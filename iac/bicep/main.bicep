@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param skuName string = 'F1'

@minValue(1)
param skuCapacity int = 1

param sqlAdministratorLogin string

@secure()
param sqlAdministratorLoginPassword string

param location string = resourceGroup().location

var hostingPlanName = 'hostingplan${uniqueString(resourceGroup().id)}'
var webSiteName = 'webSite${uniqueString(resourceGroup().id)}'
var sqlserverName = 'sqlserver${uniqueString(resourceGroup().id)}'
var catalogDatabase = 'eShopOnWeb.CatalogDb'
var identityDatabase = 'eShopOnWeb.Identity'

resource sqlserver 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlserverName_catalogDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sqlserver.name}/${catalogDatabase}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}

resource sqlserverName_identityDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sqlserver.name}/${identityDatabase}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}

resource sqlserverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2014-04-01' = {
  name: '${sqlserver.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}


resource AppInsights_webSiteName 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: 'AppInsights${webSiteName}'
  location: location
  tags: {
    displayName: 'AppInsightsComponent'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

resource webSite 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  tags: {
    'hidden-related:${hostingPlan.id}': 'empty'
    displayName: 'Website'
  }

  properties: {
      siteConfig: {
          appSettings: [
              {
                  name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
                  value: AppInsights_webSiteName.properties.InstrumentationKey
              }
              {
                  name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
                  value: '~2'

              }
              {
                  name: 'XDT_MicrosoftApplicationInsights_Mode'
                  value: 'recommended'
              }
              {
                  name: 'InstrumentationEngine_EXTENSION_VERSION'
                  value: '~1'
              }

              {
                  name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
                  value: '~1'
              }
              {
                  name: 'XDT_MicrosoftApplicationInsights_PreemptSdk'
                  value: '1'
              }
              {
                  name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
                  value: '1.0.0'
              }
              {
                  name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
                  value: '1.0.0'
              }
              {
                  name: 'DiagnosticServices_EXTENSION_VERSION'
                  value:'~3'
              }
          ]
      }
    serverFarmId: hostingPlan.id
  }
}

resource webSiteConnectionStrings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webSite.name}/connectionstrings'
  properties: {
    CatalogConnection: {
      value: 'Data Source=tcp:${sqlserver.properties.fullyQualifiedDomainName},1433;Initial Catalog=${catalogDatabase};User Id=${sqlAdministratorLogin}@${sqlserver.properties.fullyQualifiedDomainName};Password=${sqlAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
    IdentityConnection: {
      value: 'Data Source=tcp:${sqlserver.properties.fullyQualifiedDomainName},1433;Initial Catalog=${identityDatabase};User Id=${sqlAdministratorLogin}@${sqlserver.properties.fullyQualifiedDomainName};Password=${sqlAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
}


//output publishing profile
output webSiteName string = webSiteName

