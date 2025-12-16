enum QueryComparisonOperator { 
  eq, //Values are equal
  ne, // Values are not equal
  lt, //Value is less than another value
  lte, //Value is less than or equal to another value
  gt, //Value is greater than another value
  gte, //Value is greater than or equal to another value
  cArr, //array contains a value
  cArrAny, //array contains any value
  inArr, //Value is matched within an array
  ninArr, //Value is matched not within an array
  isNull,
  }

enum QueryLogicalOperator { 
  and, //Returns documents where both queries match
  or, // Returns documents where either query matches
  nor, // Returns documents where both queries fail to match
  not //Returns documents where the query does not match
}

enum QueryEvaluationOperator { 
  regex, // Allows the use of regular expressions when evaluating field values
  text, //Performs a text search
  where // Uses a JavaScript expression to match documents
}
