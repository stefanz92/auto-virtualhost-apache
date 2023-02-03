#!/bin/bash

# loop through all directories in /var/www
for dir in /var/www/*; do
  # get the directory name
  dir_name=`basename $dir`

  # check if virtual host file already exists
  if [ ! -f "/etc/apache2/sites-available/$dir_name.conf" ]; then
    # set the document root based on the location of the index file
    if [ -f "$dir/index.html" ] || [ -f "$dir/index.php" ]; then
      document_root=$dir
    elif [ -f "$dir/public/index.html" ] || [ -f "$dir/public/index.php" ]; then
      document_root="$dir/public"
    elif [ -f "$dir/web/index.html" ] || [ -f "$dir/web/index.php" ]; then
      document_root="$dir/web"
    else
      document_root=$dir
    fi

    # create the virtual host file
    echo "<VirtualHost *:80>
      ServerName $dir_name.local
      DocumentRoot $document_root
      ErrorLog \${APACHE_LOG_DIR}/error-$dir_name.log
      CustomLog \${APACHE_LOG_DIR}/access-$dir_name.log combined
      <Directory $document_root>
        AllowOverride All
        Require all granted
      </Directory>
    </VirtualHost>" > /etc/apache2/sites-available/$dir_name.conf

    # enable the virtual host
    a2ensite $dir_name.conf
    if [ $? -eq 0 ]; then
      echo "Virtual host for $dir_name.local enabled"
    else
      echo "Error: Failed to enable virtual host for $dir_name.local"
    fi

    # output entry to add to hosts file
    echo "127.0.0.1 $dir_name.local" >> /tmp/hosts_entries.txt
  else
    echo "Virtual host for $dir_name.local already exists"
  fi
done

# restart apache to apply changes
systemctl restart apache2
if [ $? -eq 0 ]; then
  echo "Apache restarted successfully"
else
  echo "Error: Failed to restart Apache"
fi

# output the entries for the hosts file
echo "Entries to add to the hosts file:"
cat /tmp/hosts_entries.txt
