//
//  Sine Calc.swift
//  Sine Convergence and Precision Analysis
//
//  Created by Edin Peskovic on 2/8/24.
//

import Foundation
import Observation

@Observable class sinSum {
    var N = 0
    var xVal = 0.0
    var sinSum = 0.0
    var prec = false
    
    func initSinSum(N: Int, xVal: Double) -> Double {
        self.N = N
        self.xVal = xVal
        
        for n in 1...N {
            let numerator = pow(-1, n-1) * pow(Decimal(xVal), 2*n-1)
            let denominator = Double(2*n-1)
            sinSum = sinSum + Double(numerator)/denominator
        }
        
        return sinSum
        
    }
    
    func getPrecision(dec: Int) -> Bool {
        let nextSum = initSinSum(N: N+1, xVal: xVal)
        let precision = sinSum * 1/Double(pow(10, dec))
        
        if (nextSum <= precision) {
            prec = true
            return prec
        }
        else {
            prec = false
            return prec
        }
    }
    
    //stops when result is as pecise as desired (i think)
    func checkPrecision(dec: Int) -> Double {
        sinSum = 0.0
        var n = 1
        while prec == false && n<=N {
            let numerator = pow(-1, n-1) * pow(Decimal(xVal), 2*n-1)
            let denominator = Double(2*n-1)
            sinSum = sinSum + Double(numerator)/denominator
            let _ = getPrecision(dec: dec)
            n = n+1
        }
        
        return sinSum
    }
    
}
