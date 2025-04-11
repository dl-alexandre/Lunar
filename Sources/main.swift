// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

struct LanderState {
    var altitude: Double = 1000    // meters
    var velocity: Double = 0       // m/s
    var fuel: Double = 500         // kg
    var time: Double = 0           // seconds
    let gravity: Double = -1.62    // Moon gravity
    let maxThrust: Double = 4.0    // m/s² upward
    let fuelBurnRate: Double = 0.5 // fuel per thrust unit per second
}

func prompt(_ text: String) -> String {
    print(text, terminator: " ")
    return readLine() ?? ""
}

func simulateStep(state: inout LanderState, thrustPercent: Double, dt: Double = 1.0) {
    let thrustAccel = state.maxThrust * (thrustPercent / 100)
    let netAccel = state.gravity + thrustAccel

    // Fuel use
    let fuelUsed = state.fuelBurnRate * thrustAccel * dt
    if fuelUsed > state.fuel {
        // Out of fuel
        state.fuel = 0
    } else {
        state.fuel -= fuelUsed
    }

    state.velocity += netAccel * dt
    state.altitude += state.velocity * dt
    state.time += dt
}

func main() {
    var state = LanderState()
    
    print("🚀 Lunar Lander - Swift Edition")
    print("Goal: Land with vertical speed < 5 m/s without running out of fuel.\n")

    while state.altitude > 0 {
        print("""
        TIME: \(Int(state.time))s
        ALTITUDE: \(String(format: "%.2f", state.altitude)) m
        VELOCITY: \(String(format: "%.2f", state.velocity)) m/s
        FUEL: \(String(format: "%.2f", state.fuel)) kg
        """)
        
        let input = prompt("Enter thrust % (0-100):")
        guard let thrust = Double(input), thrust >= 0, thrust <= 100 else {
            print("Invalid input. Try again.")
            continue
        }
        
        simulateStep(state: &state, thrustPercent: thrust)
        
        if state.fuel <= 0 {
            print("\n⚠️ Out of fuel!")
            break
        }

        print()
    }

    // Final status
    print("\n🔥 Impact!")
    print("Final velocity: \(String(format: "%.2f", state.velocity)) m/s")

    if abs(state.velocity) <= 5 {
        print("🎉 Successful landing!")
    } else {
        print("💥 Crash landing.")
    }
}

main()

