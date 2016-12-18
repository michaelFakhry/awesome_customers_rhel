name 'awesome_customers_rhel'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures awesome_customers_rhel'
long_description 'Installs/Configures awesome_customers_rhel'
version '0.1.0'

depends 'selinux', '~> 0.9'
depends 'firewall', '~> 2.5'
depends 'httpd', '~> 0.4'
depends 'mysql', '~> 7.0'
depends 'mysql2_chef_gem', '~> 1.1'
depends 'database', '~> 6.0'
# If you upload to Supermarket you should set this so your cookbook
# gets a `View Issues` link
# issues_url 'https://github.com/<insert_org_here>/awesome_customers_rhel/issues' if respond_to?(:issues_url)

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Source` link
# source_url 'https://github.com/<insert_org_here>/awesome_customers_rhel' if respond_to?(:source_url)
