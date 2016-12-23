# awesome_customers_rhel

## Step 1: Get the sources from GitHub

mkdir ~/learn-chef/cookbooks
cd ~/learn-chef/cookbooks
git clone https://github.com/michaelFakhry/awesome_customers_rhel.git


## Step 2: Run Test Kitchen

cd ~/learn-chef/cookbooks/awesome_customers_rhel
kitchen converge


## Step 3: Verify the result

From a web browser on your workstation, navigate to your site at http://192.168.33.33.


## Step 4: Destroy your Test Kitchen instance

kitchen destroy