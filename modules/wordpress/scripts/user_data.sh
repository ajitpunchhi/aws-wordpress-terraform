#!/bin/bash -xe

# Update system
yum update -y
yum install -y amazon-linux-extras
amazon-linux-extras enable php7.4
yum clean metadata
yum install -y httpd php php-mysqlnd php-fpm php-json php-devel php-gd php-mbstring php-soap php-xml php-xmlrpc php-opcache php-zip php-redis amazon-efs-utils nfs-utils awslogs jq amazon-cloudwatch-agent

# Start and enable services
systemctl start httpd
systemctl enable httpd
systemctl start php-fpm
systemctl enable php-fpm

# Mount EFS
mkdir -p /var/www/html
echo "${efs_id}:/ /var/www/html efs _netdev,tls,iam 0 0" >> /etc/fstab
mount -a

# Set up WordPress if not already installed
if [ ! -f /var/www/html/wp-config.php ]; then
    # Download and configure WordPress
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -r wordpress/* /var/www/html/
    rm -rf /tmp/wordpress latest.tar.gz
    chown -R apache:apache /var/www/html

    # Create wp-config.php
    cd /var/www/html
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/${db_name}/g" wp-config.php
    sed -i "s/username_here/${db_user}/g" wp-config.php
    sed -i "s/password_here/${db_password}/g" wp-config.php
    sed -i "s/localhost/${db_host}/g" wp-config.php

    # Generate WP salts
    SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/define( 'AUTH_KEY'/,/define( 'NONCE_SALT'/d" wp-config.php
    echo "$SALTS" >> wp-config.php

    # Set site URL
    echo "define('WP_HOME', 'https://${site_name}');" >> wp-config.php
    echo "define('WP_SITEURL', 'https://${site_name}');" >> wp-config.php

    # Enable Redis if configured
    if [ "${enable_cache}" = "true" ]; then
        echo "Installing Redis object cache..."
        wget https://downloads.wordpress.org/plugin/redis-cache.zip
        unzip redis-cache.zip -d /var/www/html/wp-content/plugins/
        rm redis-cache.zip
        chown -R apache:apache /var/www/html/wp-content/plugins/

        # Add Redis configuration to wp-config.php
        echo "define('WP_REDIS_HOST', '${redis_host}');" >> wp-config.php
        echo "define('WP_REDIS_PORT', '6379');" >> wp-config.php
        echo "define('WP_REDIS_TIMEOUT', '1');" >> wp-config.php
        echo "define('WP_REDIS_READ_TIMEOUT', '1');" >> wp-config.php
        echo "define('WP_REDIS_DATABASE', '0');" >> wp-config.php
        echo "define('WP_CACHE', true);" >> wp-config.php
    fi

    # Set up WP-CLI for automated tasks
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    
    # Set up object caching
    mkdir -p /var/www/html/wp-content/object-cache/
    cat > /var/www/html/wp-content/object-cache/object-cache.php << 'EOF'
<?php
if ( !defined('ABSPATH') ) exit;

if ( !defined('WP_CACHE') || !WP_CACHE )
    return;

if ( !class_exists('WP_Object_Cache') ):

class WP_Object_Cache {
    private $cache = array();
    private $group_ops = array();
    private $redis;

    public function __construct() {
        global $blog_id;
        if ( defined('WP_REDIS_HOST') && class_exists('Redis') ) {
            try {
                $this->redis = new Redis();
                $this->redis->connect(WP_REDIS_HOST, WP_REDIS_PORT, WP_REDIS_TIMEOUT);
                $this->redis->select(WP_REDIS_DATABASE);
            } catch (Exception $e) {
                // Redis connection failed - silently continue without caching
            }
        }
    }

    public function add($key, $data, $group = 'default', $expire = 0) {
        // Implementation details...
    }

    // Add other cache methods (get, set, etc.)
}

endif;
EOF

    # Secure WordPress
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;
fi

# Set permissions
chown -R apache:apache /var/www/html

# Configure Apache
cat > /etc/httpd/conf.d/wordpress.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/httpd/wordpress_error.log
    CustomLog /var/log/httpd/wordpress_access.log combined
</VirtualHost>
EOF

# Set up CloudWatch Logs
cat > /etc/awslogs/awslogs.conf << EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/httpd/access_log]
file = /var/log/httpd/access_log
log_group_name = ${name}-${environment}-wordpress-access
log_stream_name = {instance_id}
datetime_format = %d/%b/%Y:%H:%M:%S %z

[/var/log/httpd/error_log]
file = /var/log/httpd/error_log
log_group_name = ${name}-${environment}-wordpress-error
log_stream_name = {instance_id}
datetime_format = %d/%b/%Y:%H:%M:%S %z

[/var/log/httpd/wordpress_access.log]
file = /var/log/httpd/wordpress_access.log
log_group_name = ${name}-${environment}-wordpress-access
log_stream_name = {instance_id}
datetime_format = %d/%b/%Y:%H:%M:%S %z

[/var/log/httpd/wordpress_error.log]
file = /var/log/httpd/wordpress_error.log
log_group_name = ${name}-${environment}-wordpress-error
log_stream_name = {instance_id}
datetime_format = %d/%b/%Y:%H:%M:%S %z
EOF

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}",
      "ImageId": "\${aws:ImageId}",
      "InstanceId": "\${aws:InstanceId}",
      "InstanceType": "\${aws:InstanceType}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ]
      }
    }
  }
}
EOF

# Start CloudWatch services
systemctl start awslogsd
systemctl enable awslogsd
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# Restart Apache
systemctl restart httpd

# Success notification
echo "WordPress installation completed successfully!"