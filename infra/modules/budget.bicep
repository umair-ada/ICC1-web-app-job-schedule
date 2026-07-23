@description('Budget name (unique within the scope).')
param budgetName string = 'britedge-monthly'

@description('Monthly budget amount in the subscription currency.')
param amount int = 100

@description('Emails to notify on threshold crossings.')
param contactEmails array

@description('Threshold percentages of the budget amount that trigger alerts.')
param thresholds array = [30, 50, 70]

@description('First day of the month the budget starts tracking from (YYYY-MM-01T00:00:00Z).')
param startDate string

@description('Budget expiry (must be within 5 years of startDate).')
param endDate string

resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: budgetName
  properties: {
    amount: amount
    category: 'Cost'
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: {
      Alert30: {
        enabled: true
        operator: 'GreaterThan'
        threshold: thresholds[0]
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      Alert50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: thresholds[1]
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      Alert70: {
        enabled: true
        operator: 'GreaterThan'
        threshold: thresholds[2]
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
    }
  }
}

output budgetId string = budget.id
