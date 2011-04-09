Feature: REST requests
  In order to enhance system availability for customers
  RightSupport should provide robust REST query interfaces 
  So apps do not become hung during network failures

  Scenario: well-behaved servers
    Given 3 well-behaved servers
    When a client makes a load-balanced request to '/' with timeout 1
    Then the request should complete in less than 1 second

  Scenario: faulty servers
    Given 3 faulty servers
    When a client makes a load-balanced request to '/' with timeout 1
    Then the request should raise in less than 3 seconds

  Scenario: mixed servers
    Given 4 faulty servers
    And 4 well-behaved servers
    When a client makes a load-balanced request to '/' with timeout 1
    Then the request should complete in less than 4 seconds
