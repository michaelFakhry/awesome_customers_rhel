# Installation

the following steps are guidelines how you install and test the 'awesome_customers_rhel' which is used for learning purpose.

## Step 1: Get the sources from GitHub

$ mkdir -p ~/learn-chef/cookbooks

$ cd ~/learn-chef/cookbooks

$ git clone https://github.com/michaelFakhry/awesome_customers_rhel.git


## Step 2: Run Test Kitchen

$ cd ~/learn-chef/cookbooks/awesome_customers_rhel

$ kitchen converge


## Step 3: Verify the result

From a web browser on your workstation, navigate to your site at http://192.168.33.33.


## Step 4: Destroy your Test Kitchen instance

$ kitchen destroy

# Resources

## A step by step guide
how to carry out the 'awesome_customers_rhel' project:
https://github.com/michaelFakhry/awesome_customers_rhel/tree/master/docs/tutorial-guide-line

## Preparing environment
The following document describes basic procedures for installation and communication among chef workstation, chef-server, and chef-client (node):
https://github.com/michaelFakhry/awesome_customers_rhel/tree/master/docs/general-notes