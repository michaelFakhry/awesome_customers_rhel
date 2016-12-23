#Overview
the following document describes basic procedures for installation and communication among chef workstation, chef-server, and chef-client (node).

##Installing and configuring workstation
1. Download and install [Chef DK](https://downloads.chef.io/chefdk) which is your workstation.

2. Create the working directory for workstation, through terminal:
>```
>$ mkdir chef-workstation
>
>$ cd chef-workstation
>
>$ mkdir .chef
>```

3. Put the knife.rb to the '.chef' directory
>**NOTE**: knife.rb is generated from the chef hosted server web console

4. Move the <username>.pem generated from web console to the '.chef' directory as well.

5. If using windows cmd, you should change the cmd encoding when using any of chef commands
>```
>$ chcp 1252
>```

6. Go to the parent directory that includes the '.chef' directory and apply
>```
>$ knife ssl check
>```
>
>**OUTPUT**: should see the following:
>```
>Connecting to host api.chef.io:443
>Successfully verified certificates from 'api.chef.io'
>```

7. Create the 'cookbooks' directory in the 'chef-workstation'
>```
>$ mkdir cookbooks
>```

8. Go to the 'cookbooks' directory and clone the 'learn_chef_httpd' git project for testing
>```
>$ cd cookbooks
>$ git clone https://github.com/learn-chef/learn_chef_httpd.git
>```
>you may also use our cookbook
>```
>$ git clone https://github.com/michaelFakhry/awesome_customers_rhel.git
>```

9. Upload the 'learn_chef_httpd' project to the chef-server with the following command
>```
>$ knife cookbook upload learn_chef_httpd
>```

10. verify that the project exist on the chef-server through
>```
>$ knife cookbook list
>```

##Installing and  configuring chef-client (node)
1. Need to prepare a virtual machine that will be the node required to be configured, make sure to be able to access the node remotely through ssh either with **username and password** or with a **ssh key file**.

2. Use the **bootstrap** command to initialize the node and configure it for the first time.
>**using a username and password**
>```
>$ knife bootstrap ADDRESS --ssh-user USER --ssh-password 'PASSWORD' --sudo --use-sudo-password --node-name node1-centos --run-list 'recipe[learn_chef_httpd]'
>```
>replace **USER** with *node_username* and **PASSWORD** with *node_password* and **ADDRESS** with *hostname or ip address of the node* and **node1-centos** with the *node_name* of your choice
>
>**example:**
>```
>$ knife bootstrap 192.168.1.36 --ssh-user root --ssh-password 'centos' --sudo --use-sudo-password --node-name chef-node-1 --run-list 'recipe[learn_chef_httpd]'
>```
>**using a ssh key private key**
>```
>$ knife bootstrap ADDRESS --ssh-user USER --sudo --identity-file IDENTITY_FILE --node-name node1-centos --run-list 'recipe[learn_chef_httpd]'
>```
>Replace **USER** with *node_username* and **IDENTITY_FILE** with the *pem ssh key* to access the node and **ADDRESS** with *hostname or ip address of the node* and **node1-centos** with the *node_name* of your choice

3. Verify that the node exist:
>```
>$ knife node list
>```

4. To view information about a specific node
>```
>$ knife node show <node_name>
>```

##Updating a specific recipes
1. To update a node for example: change the file 'chef-workstation\cookbooks\learn_chef_httpd\templates\index.html.erb' with the following content
>```
><html>
> <body>
>    <h1>hello from <%= node['fqdn'] %></h1>
>  </body>
></html>
>```

2. Before provisioning you need to update the version in 'chef-workstation\cookbooks\learn_chef_httpd\metadata.rb'
>**NOTES**: 
>a. Initially when you generate a specific recipe 'throug the command '$ chef generate cookbook' the initial version value is '0.1.0'
>b. You may want to review the semantic versioning 'http://semver.org/' and follow the conventions.

3. Upload your cookbook to the chef server
>```
>$ knife cookbook upload learn_chef_httpd
>```

4. Provision the node by running the following command at the node
>```
>$ sudo chef-client
>```
>or through the workstation remotely 'knife ssh' command
>```
>$ knife ssh 192.168.1.36 'sudo chef-client' --manual-list --ssh-user root - ssh-password 'centos'
>```


##Configuring workstation to connect to chef supermarket
1. Add the configuration file '\chef-workstation\Berksfile' with content
>```
> source 'https://supermarket.chef.io'
> cookbook 'chef-client'
>```
>**NOTE**: source above is the source for public chef supermarket, and the above cookbook is provided by it.

2. Install cookbooks from the supermarket
>```
>$ berks install
>```
>**NOTE**: you will find the cookbooks downloaded in the directory '~/.berkshelf/cookbooks'

3. Use 'berks upload' to upload the cookbooks from workstation to chef server 
>**NOTE**: don't use the 'knife cookbook upload' command because the '>berks upload' will handle dependencies within the cookbook
>berks upload


##Adding a role file
1. Create a json role file in the directory 'chef-workstation\roles' and add the following content to a 'web.json' file
>
>```
>{
>   "name": "web",
>   "description": "Web server role.",
>   "json_class": "Chef::Role",
>   "default_attributes": {
>     "chef_client": {
>       "interval": 60,
>       "splay": 60
>     }
>   },
>   "override_attributes": {
>   },
>   "chef_type": "role",
>   "run_list": ["recipe[chef-client::default]",
>                "recipe[chef-client::delete_validation]",
>                "recipe[learn_chef_httpd::default]"
>   ],
>   "env_run_lists": {
>   }
>}
>```
>**NOTE: **
>- interval: specifies the number of seconds between chef-client runs. The default value is 1,800 (30 minutes).
>- splay: specifies a maximum random number of seconds that is added to the interval. Splay helps balance the load on the Chef server by ensuring that many chef-client runs are not occurring at the same interval. The default value is 300 (5 minutes).

2. Add the role to the chef-server
>```
>knife role from file roles/web.json
>```

3. To view the roles on your chef server
>```
>$ knife role list
>```

4. To view the role detail 'for example the web role'
>```
>$ knife role show web
>```

5. Specifying the node run-list
>```
>$ knife node run_list set chef-node-1 "role[web]"
>```

6. To view the node run list
>```
>$ knife node show chef-node-1 --run-list
>```

7. Run the 'sudo chef-client' to apply the new role for the individual node or to provision from workstation use
>```
>$ knife ssh localhost --ssh-port 2200 'sudo chef-client' --manual-list --ssh-user vagrant --identity-file /root/learn-chef/chef-server/.vagrant/machines/node1-centos/virtualbox/private_key
>```
>or
>```
>$ knife ssh localhost --ssh-port 2200 'sudo chef-client' --manual-list --ssh-user vagrant --identity-file /root/learn-chef/chef-server/.vagrant/machines/node1-centos/virtualbox/private_key
>```
>**example**:
>```
>$ knife ssh 192.168.1.36 --ssh-port 22 'sudo chef-client' --manual-list --ssh-user root --ssh-password 'centos'
>```

8. To view the node that applied a specific role
>```
>$ knife status 'role:web' --run-list
>```
>**OUTPUT**:
>```
>0 minutes ago, chef-node-1, ["role[web]"], centos 7.2.1511.
>```
>**NOTE**:
>Every 5–6 minutes you'll see that your node performed a recent check-in with the Chef server and ran chef-client


##Cleaning chef server
1. To delete a node data from chef server
>```
>$ knife node delete chef-node-1 --yes
>$ knife client delete chef-node-1 --yes
>```

2. Deleting a cookbook from chef server, for example deleting the 'learn_chef_httpd' cookbook
>```
>$ knife cookbook delete learn_chef_httpd --all --yes
>```
>**NOTE**:
If you omit the --all argument, you'll be prompted to select which version to delete.

3. To delete a role from chef server example 'web' role
>```
>$ knife role delete web --yes
>```

4. **VERY IMPORTANT**: if you want to reenable a specific node after deleting it from chef server, you need to manually log in to the node and delete the RSA private key file 'client.pem' which is created during the bootsrap process
>```
>sudo rm /etc/chef/client.pem
>```