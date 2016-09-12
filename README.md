# Usage

### Prepare MySQL user

Allow newrelic to query mysql with correct grants:

```sql
CREATE USER newrelic@<INSERT_IP_ADDRESS_HERE> IDENTIFIED BY '<INSERT_YOUR_PASS_HERE>';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO newrelic@<INSERT_IP_ADDRESS_HERE>;
```

## postgresql configuration
### Set up postgresql

set up your pg_hba.conf so that localhost can login with password.
A row like this helps for that:
```
host    all             all             127.0.0.1/32            md5
```

### Create user for monitoring
```
sudo su - postgres
createuser monitor
```

As postgres DBA set up password for user monitor:
```sql
ALTER USER monitor WITH PASSWORD 'secretpassword';
ALTER USER monitor WITH SUPERUSER;
```
### Chef attributes setup

Set up cog_newrelic meetme attributes in role or wherever you want like this:

```ruby
  cog_newrelic: {
    postgresql_secrets_vault: 'postgresql',
    'plugin-agent' => {
      postgresql: true,
      postgresql_dbs: {
        databasename: {
          host: 'localhost',
          port: '5432',
          user: 'monitor',
          dbname: 'postgres',
          superuser: 'True',
          relation_stats: 'True'
        }
      }
    }
  }

```

It is possible to monitor multiple databases, "databasename" is just a name, not
name of database (this is dbname attribute)

### Set up secrets

Secrets must be set up to vault 'newrelic','postgresql' if using above example.

**postgresql_secrets_vault** attribute contains vault name second part.

With above example, vault should contain this:
```
{
  "databasename":"secretpassword"
}
```

**databasename** is from attributes and password is from SQL.
