function total = getNumberOfEvals()

total = org.anon.cocoa.costfunctions.LocalInequalityConstraintCostFunction.nComparisons +...
    org.anon.cocoa.costfunctions.InequalityConstraintCostFunction.nComparisons;