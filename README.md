Alfresco offers a rich remote API using its WebScripts technology which is
based on the REST paradigm. This projects provides a set of scripts that makes
it more easy to interact with the repository and its exposed resources.

Create or change users, create sites, manage group membership form the command
line instead of the user interface.

Also great for automation: Create some hundreds of users from a table and
automatically add to a set of groups? This becomes a one liner with the
Alfresco shell tools.

# Use cases

Reported use cases have been:

* Backup User-Group relationships
* Provision demo systems
* Keep avatar pictures in sync with a 3rth party source
* pregenerate >100k thumbnail images
* Initial import of users and groups, along with user-group and group-subgroup assignements
* Create a bunch of tenants for a multi-tenancy enabled Alfresco
* Do repetitive maintenance tasks for multiple tenants in one go 

# How to start?

1. check out the scripts or download a release tarball
2. install required 3-rd party tools for json handling
   http://kmkeen.com/jshon/
3. set environment variables
4. install web-scripts from `alfresco`
5. have fun

# Environment Variables

Required environment variables:

* `ALFTOOLS_USER=<username>`
* `ALFTOOLS_PASSWORD=<password>`
* `ALFTOOLS_ENDPOINT='http://<host>.<domain>:<port>/alfresco'`

Optional environment variables:

* `ALF_VERVBOSE=<true|false>`

# Commands

Note: 'x' means working, ' ' untested with 5.1, 'X' requires
alfresco administrator privileges, '-' not working.


The available commands are:

```
[X]alfAddAuthorityToGroup.sh
[x]alfCreateCalendarEntry.sh
[X]alfCreateGroup.sh
[X]alfCreateSite.sh
[x]alfCreateTenant.sh
[x]alfCreateUser.sh
[x]alfDeleteAuthorityFromGroup.sh
[x]alfDeleteGroup.sh
[x]alfDelete.sh
[X]alfDeleteSite.sh
[x]alfDeleteUser.sh
[x]alfDeleteUserFromSite.sh
[x]alfGetCompanyHomeNodeRef.sh
[x]alfGet.sh
[x]alfGetPermissions.sh
[x]alfGetThumbnail.sh
[x]alfGetUserHomeFolder.sh
[x]alfGetUser.sh
[x]alfListGroupMembers.sh
[x]alfListGroups.sh
[x]alfListTenants.sh
[x]alfListUsers.sh
[x]alfListUsersSite.sh
[x]alfMetadata.sh
[x]alfMkdir.sh
[x]alfNodeRef2Path.sh
[x]alfPath2NodeRef.sh
[x]alfRename.sh
[x]alfResetAvatar.sh
[x]alfSearch.sh
[x]alfSetAvatar.sh
[x]alfSetPermissions.sh
[x]alfUpdateUser.sh
[x]alfUpload.sh
[X]alfWho.sh
```

Note: alfCreateSite.sh alfDeleteSite.sh alfInviteUser.sh are not
tested with Alfresco 4.x (pre-CSRF protection)

Use `-h` to get a detailed description of each command.

Example:

```shell
$ alfSearch.sh -h
usage: ./bin/alfSearch.sh [global options] [command specific options] arguments
  global options:
    -h   help       shows this help screen
    -v   verbose    displays information while executing

    -E   endpoint   Alfresco endpoint
    -S   share endpoint Alfresco share endpoint
    -U   user       Alfresco user id used in authentication
    -P   password   password used for authenticaiton

    -C   curl opts  any additional options pass to curl

  command options:
    -p property name    which property of each search result node should be printed to stdout.
                        Possible values are nodeRef(default), name, path, type, displayName, title,
                        description, modifiedOn, modifiedBy, modifiedByUser, size, mimetype, path
    -m [property|json]  output mode: 'property' (default) prints the value of the property given by -p.
                        Mode 'json' prints the whole result set as a json object.

  command arguments:
    SEARCHTERM       an Alfresco search term

  command explanation:
    the alfSearch.sh command issues a search against the Alfresco repository and prints
    each the nodeRef of each hit.

  usage examples:

    ./alfSearch.sh 'this is fun'
       --> executes a full text search for 'this is fun'
    ./alfSearch.sh 'TYPE:myns:mydoctype' | wc -l
       --> prints the number of documents of type myns:mydoctype

  side note about the Alfresco search and the implications of the
  various implementations

    If Alfresco uses the LUCENE search backend, the result list will
	not be stable. This is due to internal performance optimizations
	done by Alfresco and depends on cache filling levels and system
	load. As a result the search will return more results on
	subsequence executions.

    If Alfresco is configured to use the SOLR search backend, the
	result list will be 'eventual consistent'. This simple means,
	the Alfresco content is indexed by a background job in an
	asynchronous manner and and therefore will not contain all
	content at any point in time.  However, the result list is
	stable, taking into account what is indexed so far.

  the alfresco shell tools are created by
    lothar.maerkle@ecm4u.de - http://www.ecm4u.de - http://www.ecm-market.de
    anybody jumps in?
```
