import os, frappe, json

from frappe.commands.site import _new_site

site_name = os.environ.get("SITE_NAME", 'localhost')
mariadb_root_username = os.environ.get("MYSQL_ROOT_USER", 'root')
mariadb_root_password = os.environ.get("MYSQL_ROOT_PASSWORD", 'root')
install_erpnext = os.environ.get("INSTALL_ERPNEXT", None)

frappe.init(site_name, new_site=True)

_new_site(
    None,
    site_name,
    mariadb_root_username=mariadb_root_username,
    mariadb_root_password=mariadb_root_password,
    admin_password=os.environ.get("ADMIN_PASSWORD", 'admin'),
    verbose=True,\
    source_sql=None,
    force=False,
    reinstall=False,
    db_type=os.environ.get("DB_TYPE", 'mariadb')
)

config = None
with open('common_site_config.json') as config_file:
    config = json.load(config_file)

site_config = None
with open('{site_name}/site_config.json'.format(site_name=site_name)) as site_config_file:
    site_config = json.load(site_config_file)

# update User's host to '%' required to connect from any container
command = 'mysql -h{db_host} -u{mariadb_root_username} -p{mariadb_root_password} -e '.format(
    db_host=config.get('db_host'),
    mariadb_root_username=mariadb_root_username,
    mariadb_root_password=mariadb_root_password
)
command += "\"UPDATE mysql.user SET Host = '%' where User = '{db_name}'; FLUSH PRIVILEGES;\"".format(
    db_name=site_config.get('db_name')
)
os.system(command)

# Set db password
command = 'mysql -h{db_host} -u{mariadb_root_username} -p{mariadb_root_password} -e '.format(
    db_host=config.get('db_host'),
    mariadb_root_username=mariadb_root_username,
    mariadb_root_password=mariadb_root_password
)
command += "\"SET PASSWORD FOR '{db_name}'@'%' = PASSWORD('{db_password}'); FLUSH PRIVILEGES;\"".format(
    db_name=site_config.get('db_name'),
    db_password=site_config.get('db_password')
)
os.system(command)

# Grant permission to database
command = 'mysql -h{db_host} -u{mariadb_root_username} -p{mariadb_root_password} -e '.format(
    db_host=config.get('db_host'),
    mariadb_root_username=mariadb_root_username,
    mariadb_root_password=mariadb_root_password
)
command += "\"GRANT ALL PRIVILEGES ON \`{db_name}\`.* TO '{db_name}'@'%'; FLUSH PRIVILEGES;\"".format(
    db_name=site_config.get('db_name')
)
os.system(command)

exit(0)
