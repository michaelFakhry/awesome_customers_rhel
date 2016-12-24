#Overview
The following document describes the procedures carried out to create the awesome_customers_rhel

##Creating your own cookbook
1. Initialization steps
>```
>$ mkdir chef-workstation
>$ cd chef-workstation
>$ mkdir .chef
>$ mkdir cookbooks
>$ chef generate cookbook cookbooks/awesome_customers_rhel
>```

2. Replace the content of 'chef-workstation/cookbooks/awesome_customers_rhel/.kitchen.yml' with
>```
>---
>driver:
>  name: vagrant
>  network:
>    - ["private_network", {ip: "192.168.33.33"}]
>
>provisioner:
>  name: chef_zero
>
>platforms:
>  - name: centos-7.2
>
>suites:
>  - name: default
>    run_list:
>      - recipe[awesome_customers_rhel::default]
>    attributes:
>```	
3. Check the status of the instance, you will note its '**Not Created**'
>```
>$ cd cookbooks/awesome_customers_rhel
>$ kitchen list
>```
>**OUTPUT**:
>```
>Instance           Driver   Provisioner  Verifier  Transport  Last Action
default-centos-72  Vagrant  ChefZero     Busser    Ssh        <Not Created>
>```

4. Run the following command to help Test Kitchen manage dependent cookbooks that you'll use later
>```
>$ berks install
>```

5. Preparing a virtual machine that will be used to test a recipe before provisioning to chef server
>```
>$ kitchen converge
>```

6. To destroy your instance go through the following command
>```
>$ kitchen destroy
>```

7. Login to the mahcine
>```
>$ kitchen login
>```

8. When doing a specific recipe you may need to reference another one; do this by adding the dependency at the end of file 'chef-workstation\cookbooks\awesome_customers_rhel\metadata.rb'
>```
>depends 'selinux', '~> 0.9'
>```
>**NOTE**: 
>- its too important not to reinvent the wheel, accordingly you may find other recipes here https://supermarket.chef.io/cookbooks that you may use
>- you can view all information about a specific cookbook through the command:
>```
>$ knife supermarket show selinux | grep latest_version
>```

9. Update the file 'chef-workstation\cookbooks\awesome_customers_rhel\recipes\default.rb' to include the selinux library
>```
>include_recipe 'selinux::permissive'
>```

10. Now lets apply the changes that is been made to machine that we prepared earlier
>```
>$ kitchen converge
>$ kitchen login
>```
**NOTE**: You may find issues logging to the machine due to vagrant is shutted down you may need to do a manual step upping the vagrant through the following commands
>```
>$ cd chef-workstation\cookbooks\awesome_customers_rhel\.kitchen\kitchen-vagrant\kitchen-awesome_customers_rhel-default-centos-72
>$ vagrant up
>```

11. Check the sestatus after provisioning thorugh the command
>```
>$ sestatus
>```
>**NOTE**: 
>you should see the current mode set to 'permissive'
>**OUTPUT**:
>```
>SELinux status:                 enabled
>SELinuxfs mount:                /sys/fs/selinux
>SELinux root directory:         /etc/selinux
>Loaded policy name:             targeted
>Current mode:                   permissive
>Mode from config file:          permissive
>Policy MLS status:              enabled
>Policy deny_unknown status:     allowed
>Max kernel policy version:      28
>```

12. Now lets add the firewall dependency as well to inbound access on port 22 that helps with running chef-client from workstation and also allowing access on port 80
add to the end of the file 'chef-workstation\cookbooks\awesome_customers_rhel\metadata.rb'
>```
>depends 'firewall', '~> 2.5'
>```

13. Generate a firewall recipe within the 'awesome_customers_rhel' 
>```
>$ chef generate recipe cookbooks/awesome_customers_rhel firewall
>```
>**NOTE**: this way you have 2 'firewall' recipes one from the supermarket and the one you just created

14. Define attributes for the recipe named 'default'
>``
>$ chef generate attribute cookbooks/awesome_customers_rhel default
>```
>**NOTE:
>This command adds the default.rb attribute file to the
>~/learn-chef/cookbooks/awesome_customers_rhel/attributes directory.

15. Update the '\chef-workstation\cookbooks\awesome_customers_rhel\attributes\default.rb' with the following values
>```
>default['firewall']['allow_ssh'] = true
>default['firewall']['firewalld']['permanent'] = true
>default['awesome_customers_rhel']['open_ports'] = 80
>```
>**NOTE**:
>- Line 1 specifies that the firewall cookbook's default recipe should open port 22 to allow SSH access.
>- Line 2 specifies that all rules should be set permanently so that they persist after reboot.
>- Line 3 which is default['awesome_customers_rhel']['open_ports'] node attribute is a custom node attribute that we define, it also could be an array like [80, 443].

16. Add the the following content to the 'firewall.rb' .A cookbook can define resource types for other cookbooks to use
>manually without attributes
>```
>ports = [22, 80]
>firewall_rule "open ports #{ports}" do
>  port ports
>end
>
>firewall 'default' do
>  action :save
>end
>```
> after adding attributes
>```
>include_recipe 'firewall::default'
>
>ports = node['awesome_customers_rhel']['open_ports']
>firewall_rule "open ports #{ports}" do
>  port ports
>end
>
>firewall 'default' do
>  action :save
>end
>```

17. Include the firewall recipe in the 'awesome_customers_rhel\recipes\default.rb' (main file)
>```
>include_recipe 'awesome_customers_rhel::firewall'
>```

18. Provision to machine then test
>```
>$ kitchen converge
>$ kitchen login
>$ systemctl status firewalld
>```
>**OUTPUT**:
>should see the firewall is running
>```
>$ sudo firewall-cmd --direct --permanent --get-all-rules
>```
>**OUTPUT**:
>should see the active ports 22 and 80 are running

19. Create a web admin user and group by first creating a recipe that well take care of the operation
>```
>$ chef generate recipe cookbooks/awesome_customers_rhel web_user
>```

20. Add the web_admin user and group to the 'attributes\default.rb' attributes file 
>```
>default['awesome_customers_rhel']['user'] = 'web_admin'
>default['awesome_customers_rhel']['group'] = 'web_admin'
>```

21. Update the 'web_user.rb' to include the 'web_admin' group and the 'web_admin' user
>manually without attributes\default.rb
>```
>group 'web_admin'
>
>user 'web_admin' do
>  group 'web_admin'
>  system true
>  shell '/bin/bash'
>end
>```
>using the attributes/default.rb
>```
>group node['awesome_customers_rhel']['group']
>
>user node['awesome_customers_rhel']['user'] do
>  group node['awesome_customers_rhel']['group']
>  system true
>  shell '/bin/bash'
>end
>```

22. Include the new recipe in the main 'default.rb'
>```
>include_recipe 'awesome_customers_rhel::web_user'
>```

23. apply and test 
>```
>$ kitchen converge
>$ kitchen login
>```
>verify the user is created
>```
>$ getent passwd web_admin
>```
>**OUTPUT**:
>```
>web_admin:x:995:1001::/home/web_admin:/bin/bash
>```
>verify that the group ID refers to the group name "web_admin"
>```
>$ getent passwd web_admin | cut -d: -f4 | xargs getent group | cut -d: -f1
>```
>**OUTPUT**:
>```
>web_admin
>```

24. Working on installing the httpd service by modifying the metadata.rb
>```
>depends 'httpd', '~> 0.4'
>```

25. Create a web recipe
>```
>$ chef generate recipe cookbooks/awesome_customers_rhel web
>```

26. Add the contents to the 'web.rb'
>```
>httpd_service 'customers' do
>  mpm 'prefork'
>  action [:create, :start]
>end
>
># Add the site configuration.
>httpd_config 'customers' do
>  instance 'customers'
>  source 'customers.conf.erb'
>  notifies :restart, 'httpd_service[customers]'
>end
>
># Create the document root directory.
>directory node['awesome_customers_rhel']['document_root'] do
>  recursive true
>end
>
># Write the home page.
>file "#{node['awesome_customers_rhel']['document_root']}/index.html" do
>  content '<html>This is a placeholder</html>'
>  mode '0644'
>  owner node['awesome_customers_rhel']['user']
>  group node['awesome_customers_rhel']['group']
>end
>```

27. Generate a template for the configuration file of apache
>```
>$ chef generate template cookbooks/awesome_customers_rhel customers.conf
>```

28. Add the contents of the template file
>```
><VirtualHost *:80>
>  ServerName <%= node['hostname'] %>
>  ServerAdmin 'ops@example.com'
>
>  DocumentRoot <%= node['awesome_customers_rhel']['document_root'] %>
>  <Directory "/">
>          Options FollowSymLinks
>          AllowOverride None
>  </Directory>
>  <Directory <%= node['awesome_customers_rhel']['document_root'] %> >
>          Options Indexes FollowSymLinks MultiViews
>          AllowOverride None
>          Require all granted
>  </Directory>
>
>  ErrorLog /var/log/httpd/error.log
>
>  LogLevel warn
>
>  CustomLog /var/log/httpd/access.log combined
>  ServerSignature Off
>
>  AddType application/x-httpd-php .php
>  AddType application/x-httpd-php-source .phps
>  DirectoryIndex index.php index.html
></VirtualHost>
>```
>**NOTE**:
>node['hostname'] is one of many built-in node attributes find them here >https://docs.chef.io/ohai.html#automatic-attributes

29. Set the web.rb to run by adding the include statement to 'default.rb'
>```
>include_recipe 'awesome_customers_rhel::web'
>```

30. Apply and test
>```
>$ kitchen converge
>$ kitchen login
>```

31. Check
>```
>$ stat -c "%A (%a) %U %G" /var/www/customers/public_html/index.html
>```
>**OUTPUT**:
>```
>-rw-r--r-- (644) web_admin web_admin
>```
>also check the service
>```
>$ sudo service httpd-customers status
>```
>verify the homepage exist
>```
>$ more /var/www/customers/public_html/index.html
>```

32. adding a mysql password, modify the 'attributes/default.rb' append the following to generate a password for the root and admin users of the database
>```
>def random_password
>  require 'securerandom'
>  SecureRandom.base64
>end
>
>normal_unless['awesome_customers_rhel']['database']['root_password'] = random_password
>normal_unless['awesome_customers_rhel']['database']['admin_password'] = random_password
>```
>**NOTE**: normal_unless sets the node attribute only if the attribute has no value.

33. modify the '.kitchen.yml' to set a specific password for the development environment
>```
>---
>driver:
>  name: vagrant
>  network:
>    - ["private_network", {ip: "192.168.33.33"}]
>
>provisioner:
>  name: chef_zero
>
>platforms:
>  - name: centos-7.2
>
>suites:
>  - name: default
>    run_list:
>      - recipe[awesome_customers_rhel::default]
>    attributes:
>      awesome_customers_rhel:
>        database:
>          root_password: 'mysql_root_password'
>          admin_password: 'mysql_admin_password'
>```		  
		  
34. adding mysql component, adding its dependency, modify the 'metadata.rb' and add the mysql dependency
>```
>depends 'mysql', '~> 7.0'
>```

35. Generate the database recipe 
>```
>$ chef generate recipe cookbooks/awesome_customers_rhel database
>```

36. Install the MySQL client and service packages by modifying the 'database.rb' that is generated with the following content
>```
># Configure the MySQL client.
>mysql_client 'default' do
>  action :create
>end
>
># Configure the MySQL service.
>mysql_service 'default' do
>  initial_root_password node['awesome_customers_rhel']['database']['root_password']
>  action [:create, :start]
>end
>```

37. Append an include_recipe statement to your default recipe, 'recipe\default.rb'
>```
>include_recipe 'awesome_customers_rhel::database'
>```

38. Apply and test 
>```
>$ kitchen converge
>$ kitchen login
>```
>verify that mysql database is created
>```
>$ sudo netstat -tap | grep mysql
>```
>**OUTPUT**:
>```
>tcp        0      0 0.0.0.0:mysql           0.0.0.0:*               LISTEN      28435/mysqld
>```
>```
>$ mysqlshow -h 127.0.0.1 -uroot -pmysql_root_password
>```
>view tables in the database

#Configuring database
1. Add the 'mysql2_chef_gem' and 'database' to be included from chef supermarket in the 'metadata.rb'
>```
>depends 'mysql2_chef_gem', '~> 1.1'
>depends 'database', '~> 6.0'
>```

2. Add attributes in 'default.rb' for new database name, user, host, and password.
>```
>default['awesome_customers_rhel']['database']['dbname'] = 'my_company'
>default['awesome_customers_rhel']['database']['host'] = '127.0.0.1'
>default['awesome_customers_rhel']['database']['root_username'] = 'root'
>default['awesome_customers_rhel']['database']['admin_username'] = 'db_admin'
>```

3. Update the 'database.rb' to take care of database creation and adding user and granting him access to database
>```
># Install the mysql2 Ruby gem.
>mysql2_chef_gem 'default' do
>  action :install
>end
>
># Create the database instance.
>mysql_database node['awesome_customers_rhel']['database']['dbname'] do
>  connection(
>    :host => node['awesome_customers_rhel']['database']['host'],
>    :username => node['awesome_customers_rhel']['database']['root_username'],
>    :password => node['awesome_customers_rhel']['database']['root_password']
>  )
>  action :create
>end
>
># Add a database user.
>mysql_database_user node['awesome_customers_rhel']['database']['admin_username'] do
>  connection(
>    :host => node['awesome_customers_rhel']['database']['host'],
>    :username => node['awesome_customers_rhel']['database']['root_username'],
>    :password => node['awesome_customers_rhel']['database']['root_password']
>  )
>  password node['awesome_customers_rhel']['database']['admin_password']
>  database_name node['awesome_customers_rhel']['database']['dbname']
>  host node['awesome_customers_rhel']['database']['host']
>  action [:create, :grant]
>end
>```

4. Add a database script to create a table and some records within.
First generate a file that will hold the sql script, the file exists in the directory '\awesome_customers_rhel\files\default'
>```
>$ chef generate file cookbooks/awesome_customers_rhel create-tables.sql
>```
Second add the following script as an example
>```
>CREATE TABLE customers(
>  id CHAR (36) NOT NULL,
>  PRIMARY KEY(id),
>  first_name VARCHAR(64),
>  last_name VARCHAR(64),
>  email VARCHAR(64)
>);
>
>INSERT INTO customers ( id, first_name, last_name, email ) VALUES ( uuid(), 'Jane', 'Smith', >'jane.smith@example.com' );
>INSERT INTO customers ( id, first_name, last_name, email ) VALUES ( uuid(), 'Dave', 'Richards', >'dave.richards@example.com' );
>```

5. Update the 'database.rb' to execute the script by reading the sql file, saving it to a temp path, then executing it
>```
># Create a path to the SQL file in the Chef cache.
>create_tables_script_path = File.join(Chef::Config[:file_cache_path], 'create-tables.sql')
>
># Write the SQL script to the filesystem.
>cookbook_file create_tables_script_path do
>  source 'create-tables.sql'
>  owner 'root'
>  group 'root'
>  mode '0600'
>end
>
># Seed the database with a table and test data.
>execute "initialize #{node['awesome_customers_rhel']['database']['dbname']} database" do
>  command "mysql -h #{node['awesome_customers_rhel']['database']['host']} -u #{node['awesome_customers_rhel']['database']['admin_username']} -p#{node['awesome_customers_rhel']['database']['admin_password']} -D #{node['awesome_customers_rhel']['database']['dbname']} < #{create_tables_script_path}"
>  not_if  "mysql -h #{node['awesome_customers_rhel']['database']['host']} -u #{node['awesome_customers_rhel']['database']['admin_username']} -p#{node['awesome_customers_rhel']['database']['admin_password']} -D #{node['awesome_customers_rhel']['database']['dbname']} -e 'describe customers;'"
>end
>```

6. Apply and test
>```
>$ kitchen converge
>$ kitchen login
>```
>verify that 'my_company' database is created
>```
>$ mysqlshow -h 127.0.0.1 -uroot -pmysql_root_password
>```
>verify that 'db_admin' is enabled as a local database user
>```
>$ mysql -h 127.0.0.1 -uroot -pmysql_root_password -e "select user,host from mysql.user;"
>```
>verify that 'db_admin' has rights only to 'my_company' database
>```
>$ mysql -h 127.0.0.1 -uroot -pmysql_root_password -e "show grants for 'db_admin'@'127.0.0.1';"
>```
>verify that 'customers' database table exists and contains the sample data
>```
>$ mysql -h 127.0.0.1 -uroot -pmysql_root_password -Dmy_company -e "select id,first_name from customers;"

##Installing php module
1. Install the 'mod_php' apache module and the 'php-mysql' package, by appending the following in 'web.rb' recipe
>```
># Install the mod_php Apache module.
>httpd_module 'php' do
>  instance 'customers'
>end
>
># Install php-mysql.
>package 'php-mysql' do
>  action :install
>  notifies :restart, 'httpd_service[customers]'
>end
>```

2. Generate a template file for index.php
>```
>$ chef generate template cookbooks/awesome_customers_rhel index.php
>```

3. Replace the home page that was found in the 'web.rb' to read from a template
>```
># Write the home page.
>template "#{node['awesome_customers_rhel']['document_root']}/index.php" do
>  source 'index.php.erb'
>  mode '0644'
>  owner node['awesome_customers_rhel']['user']
>  group node['awesome_customers_rhel']['group']
>end
>```

4. Modify the 'index.php.erb' file to include
>```
><!DOCTYPE html>
><html lang="en">
><head>
>    <title>Customers</title>
>    <style>
>      table, th, td {
>        border: 1px solid black;
>        border-collapse: collapse;
>        font-family: sans-serif;
>        padding: 5px;
>      }
>      table tr:nth-child(even) td {
>        background-color: #95c7ea;
>      }
>    </style>
></head>
><body>
><?php
>$servername = "<%= node['awesome_customers_rhel']['database']['host'] %>";
>$username = "<%= node['awesome_customers_rhel']['database']['admin_username'] %>";
>$password = "<%= node['awesome_customers_rhel']['database']['admin_password'] %>";
>$dbname = "<%= node['awesome_customers_rhel']['database']['dbname'] %>";
>
>// Create connection
>$conn = new mysqli($servername, $username, $password, $dbname);
>
>// Check connection
>if ($conn->connect_error) {
>    die("Connection failed: " . $conn->connect_error);
>}
>
>// Perform SQL query
>$sql = "SELECT * FROM customers";
>$result = $conn->query($sql);
>
>if ($result->num_rows > 0) {
>    echo "<table>\n";
>    // Output data of each row
>    while($row = $result->fetch_assoc()) {
>      echo "\t<tr>\n";
>      foreach ($row as $col_value) {
>          print "\t\t<td>$col_value</td>\n";
>      }
>      echo "\t</tr>\n";
>    }
>    echo "</table>";
>} else {
>    echo "0 results";
>}
>
>// Close connection
>$conn->close();
>?>
></body>
></html>
>```

5. Apply and test
>```
>$ kitchen converge
>$ kitchen login
>```
>```
>$ curl localhost
>```
>**OUTPUT**:
>```
><!DOCTYPE html>
><html lang="en">
><head>
>    <title>Customers</title>
>    <style>
>      table, th, td {
>        border: 1px solid black;
>        border-collapse: collapse;
>        font-family: sans-serif;
>        padding: 5px;
>      }
>      table tr:nth-child(even) td {
>        background-color: #95c7ea;
>      }
>    </style>
></head>
><body>
><table>
>        <tr>
>                <td>3454df17-c52d-11e6-99be-6c834df7f2d3</td>
>                <td>Jane</td>
>                <td>Smith</td>
>                <td>jane.smith@example.com</td>
>        </tr>
>        <tr>
>                <td>34571dec-c52d-11e6-99be-6c834df7f2d3</td>
>                <td>Dave</td>
>                <td>Richards</td>
>                <td>dave.richards@example.com</td>
>        </tr>
></table></body>
></html>
>```

##Running application on node
1. Install the dependency 'awesome_customers_rhel' in the chef workstation
>```
>$ cd awesome_customers_rhel
>$ berks install
>```
>**NOTE**: berks install will download all dependent cookbooks from chef supermarket and saves them in '~/.berkshelf/cookbooks' directory

2. Upload to chef server
>```
>$ cd awesome_customers_rhel
>$ berks upload
>```
>verify that upload is succeeded
>```
>$ knife cookbook list
>```

3. Bootstrap your node with the command
>```
>$ knife bootstrap ADDRESS --ssh-user USER --sudo --identity-file IDENTITY_FILE --node-name customers_web_app --run-list 'recipe[awesome_customers_rhel]'
>```
>**example**:
>```
>$ knife bootstrap 192.168.1.45 --ssh-user root --sudo --identity-file ~\michael.pem --node-name customers_web_app --run-list 'recipe[awesome_customers_rhel]'
>```