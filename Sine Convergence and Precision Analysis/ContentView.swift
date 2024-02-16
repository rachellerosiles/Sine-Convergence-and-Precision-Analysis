//
//  ContentView.swift
//  Sine Convergence and Precision Analysis
//
//  Created by Rachelle Rosiles on 2/8/24.
//


import SwiftUI

struct ContentView: View {
    
    @State var guess = ""
    @State private var totalInput: Int? = 1 //l -> x
    //@State var besselResultArray :[(direction: String, xValue: Double, order: Int, start: Int, besselValue: Double)] = []
    @State var sinResultsArray :[(direction: String, xValue: Double, order: Int, sinValue: Double)] = []
    //direction: String, xValue: Double, order: Int, besselValue: Double
    private var intFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    
    var body: some View {
    
       VStack {
            HStack {
                
                TextEditor(text: $guess)

                
                Button("Calculate Sine", action:
                    
                    calculateSinFunc
                
                )
                    }
            .frame(minHeight: 300, maxHeight: 800)
            .frame(minWidth: 480, maxWidth: 800)
            .padding()
        
        HStack{
            
            Text(verbatim: "Order:")
            .padding()
            TextField("Total", value: $totalInput, formatter: intFormatter)
        
                .padding()
            
            }
               
        }
        
    }

    
    func calculateSinFunc()   {

        let xmax = 1.0                    /* max of x  */
        let xmin = 0.1                     /* min of x >0  */
        let step = 0.1                      /* delta x  */
        let terms = totalInput!                      /* terms in summation */
            //let start = order + 25                      /* used for downward algorithm */
        //var x = 0.0
        var maxIndex = 0
            
        sinResultsArray.removeAll()
            
        guess = String(format: "J%d(x)\n", terms)
        guess += "Start time \(Date())\n"
        let startTime : DispatchTime = .now()
            
        maxIndex = Int(((xmax-xmin)/step))+1

        let theMaxIndex = maxIndex
        
        Task{
        
            
                let _ = await withTaskGroup(of: Void.self /* this is the return from the taskGroup*/,
                                                                   returning: Void.self /* this is the return of all of the results */,
                                                                   body: { taskGroup in  /*This is the body of the task*/
                    
                    // We can use `taskGroup` to spawn child tasks here.
                    for index in (0...theMaxIndex)
                    {
                        taskGroup.addTask {
                            
                            //Start the calculation
                            await calculateSinSum(index: index, step: step, xmin: xmin, order: terms) /*calculateUpwardDownwardBessel(index: index, step: step, xmin: xmin, order: order, start: start)*/
                            
                            
                           // return index /* this is the return from the taskGroup*/
                            
                        }
                        
                    }
                    
                    
                    
                    // Collate the results of all child tasks
                   // var combinedTaskResults :[Int] = []
                  //  for await result in taskGroup {
                        
                  //      combinedTaskResults.append(result)
                  //  }
                    
                    
                    
                  //  return combinedTaskResults  /* this is the return from the result collation */
                    
                })
                
                //Do whatever processing that you need with the returned results of all of the child tasks here.
                
                // Sort the results based upon the direction of the result
                let sortedFinishedResults = sinResultsArray.sorted(by: { $0.1 < $1.1 })
                
                await clearSinArray()
            
                await updateSinArray(array: sortedFinishedResults)
                
                        var guessString = ""
            
                        for item in sortedFinishedResults{
            
            
                            guessString += String(format: "x = %f", item.xValue)
                            guessString += " "
                            guessString += item.direction
                            guessString += " "
                            guessString += String(format: "Bessel = %7.5e", item.sinValue)
                            guessString += "\n"
            
            
                        }
            
             guessString += "End time \(Date())\n"
            let duration = startTime.distance(to: .now())
            guessString += "Elapsed time \(duration)\n"
            
            // Display the sorted text in the GUI
                       
                        await updateGUI(text: guessString)
               
                
                
            }
            
        
        }
        
        //func calculateUpwardDownwardBessel(index: Int, step: Double, xmin: Double, order: Int, start: Int) async {
    func calculateSinSum(index: Int, step: Double, xmin: Double, order: Int) async {
                
                let resultsOfTaskCalculation = await withTaskGroup(of: (direction: String, xValue: Double, order: Int, sinValue: Double).self /* this is the return from the taskGroup*/,
                                                                   returning: [(direction: String, xValue: Double, order: Int, sinValue: Double)].self /* this is the return of all of the results */,
                                                                   body: { taskGroup in  /*This is the body of the task*/
                    
                    // We can use `taskGroup` to spawn child tasks here.
                    
                    
                    taskGroup.addTask {
                        
                        let x = Double(index)*step + xmin
                        
                        //Create a new instance of the Bessel Function Calculator object so that each has it's own calculating function to avoid potential issues with reentrancy problem
                        //let downwardResult = await BesselFunctionCalculator().calculateDownwardRecursion(xValue: x, order: order, start: start)
                        let sumresult = await sinSum().initSinSum(N: order, inputXVal: x)
                        
                        return (sumresult)
                        //direction: "Downward", xValue: xValue, order: order, start: start, besselValue: downwardBessel /* this is the return from the taskGroup*/
                        
                    }
                    taskGroup.addTask {
                        
                        let x = Double(index)*step + xmin
                        //Create a new instance of the Bessel Function Calculator object so that each has it's own calculating function to avoid potential issues with reentrancy problem
                        //let upperResult = await BesselFunctionCalculator().calculateUpwardRecursion(xValue: x, order: order)
                        let mathResult = await sinSum().formatSinBuiltin(xVal: x)
                        return (mathResult)  /* this is the return from the taskGroup*/
                        
                    }
                    
                    
                    // Collate the results of all child tasks
                    var combinedTaskResults :[(direction: String, xValue: Double, order: Int, sinValue: Double)] = []
                    for await result in taskGroup {
                        
                        combinedTaskResults.append(result)
                    }
                    
                    return combinedTaskResults  /* this is the return from the result collation */
                    
                })
                
                //Do whatever processing that you need with the returned results of all of the child tasks here.
                
                // Sort the results based upon the direction of the result
                let sortedCombinedResults = resultsOfTaskCalculation.sorted(by: { $0.0 > $1.0 })
                
                await updateSinArray(array: sortedCombinedResults)
                
            return
        }
        
        /// updateGUI
        /// This adds the text String to the text displayed in the GUI.
        /// This function runs on the Main Thread only
        /// - Parameter text: text to be added so that it can be displayed
        @MainActor func updateGUI(text:String){
            
            guess += text
            
        }
        
        @MainActor func updateSinArray(array:[(direction: String, xValue: Double, order: Int, sinValue: Double)]){
            
            sinResultsArray += array
            //besselResultArray += array
            
        }
        
        @MainActor func clearSinArray(){
            
            sinResultsArray = []
            
           
            
        }


    }

    #Preview {
        ContentView()
    }
