using 'main.bicep'

param location = 'francecentral'
param namePrefix = 'britedge'
param environment = 'dev'
param pgAdminLogin = 'britedgeadmin'
param pgAdminPassword = readEnvironmentVariable('PG_ADMIN_PASSWORD')
