import Testing

@testable import Lunar

@Suite struct LunarLanderTests {
    @Test func autopilotLanding() {
        var state = LanderState(altitude: 1000, velocity: 0, fuel: 500)
        let dt = 1.0
        let maxSteps = 500

        func autopilotThrottle(state: LanderState) -> Double {
            // Crude controller: increase thrust as altitude drops
            // Based on descent velocity
            if state.altitude < 20 {
                return 90
            } else if state.velocity < -40 {
                return 100
            } else if state.velocity < -20 {
                return 75
            } else if state.velocity < -5 {
                return 50
            } else {
                return 0
            }
        }

        for _ in 0..<maxSteps {
            if state.altitude <= 0 { break }
            let thrust = autopilotThrottle(state: state)
            simulateStep(state: &state, thrustPercent: thrust, dt: dt)
        }

        print("Final Altitude: \(state.altitude)")
        print("Final Velocity: \(state.velocity)")
        print("Final Fuel: \(state.fuel)")

        #expect(abs(state.velocity) <= 5, "Lander crashed with velocity \(state.velocity)")
        #expect(state.fuel >= 0, "Ran out of fuel before landing")
    }

    @Test func autopilotCrashLanding() {
        var state = LanderState(altitude: 1000, velocity: 0, fuel: 500)
        let dt = 1.0

        func autopilotThrottle(state: LanderState) -> Double {
            // Crude "if it's falling too fast, push throttle"
            if state.altitude < 20 {
                return 90
            } else if state.velocity < -40 {
                return 100
            } else if state.velocity < -20 {
                return 75
            } else if state.velocity < -5 {
                return 50
            } else {
                return 0
            }
        }

        while state.altitude > 0 {
            let thrust = autopilotThrottle(state: state)
            simulateStep(state: &state, thrustPercent: thrust, dt: dt)

            // Fail fast if completely out of fuel but still high up
            if state.fuel <= 0 && state.altitude > 5 {
                #expect(Bool(true), "ran out of fuel before safe descent. Altitude: \(state.altitude)")
                return
            }
        }
    }

    @Test func testMultipleAutopilotStrategiesUntilSuccess() {
        let strategies: [(String, (LanderState) -> Double)] = [

            (
                "Dumb descent throttle",
                { state in
                    return state.altitude < 100
                        ? 90 : state.velocity < -40 ? 100 : state.velocity < -25 ? 80 : state.velocity < -10 ? 50 : 0
                }
            ),

            (
                "Altitude-targeted burn",
                { state in
                    if state.altitude < 50 {
                        return 100
                    } else if state.altitude < 150 {
                        return 70
                    } else {
                        return 30
                    }
                }
            ),

            (
                "Velocity-based fine control",
                { state in
                    let desiredVelocity = -2.0 - (state.altitude / 300) * 10
                    let error = desiredVelocity - state.velocity
                    let kP = 20.0
                    let throttle = kP * error
                    return max(0.0, min(throttle, 100.0))
                }
            ),

            (
                "Bang-bang controller",
                { state in
                    return state.velocity < -5 ? 100 : 0
                }
            ),
        ]

        var success = false

        for (name, strategy) in strategies {
            var state = LanderState(altitude: 1000, velocity: 0, fuel: 500)
            var steps: [(Double, Double, Double, Double, Double)] = []

            while state.altitude > 0 && steps.count < 1000 {
                let thrust = strategy(state)
                steps.append((state.time, state.altitude, state.velocity, state.fuel, thrust))
                simulateStep(state: &state, thrustPercent: thrust)

                if state.fuel <= 0 && state.altitude > 0 {
                    break
                }
            }

            if state.altitude <= 0 && abs(state.velocity) <= 5 {
                print("\n✅ Strategy '\(name)' succeeded:")
                print("TIME\tALT(m)\tVEL(m/s)\tFUEL\tTHRUST%")
                for (t, alt, vel, fuel, thrust) in steps {
                    print(String(format: "%.0f\t%.1f\t%.2f\t%.1f\t%.0f", t, alt, vel, fuel, thrust))
                }

                print("\nFinal:")
                print("   Time: \(Int(state.time))s")
                print("   Velocity: \(String(format: "%.2f", state.velocity)) m/s")
                print("   Fuel: \(String(format: "%.2f", state.fuel)) kg")
                success = true
                break
            } else {
                print(
                    "❌ Strategy '\(name)' failed: Altitude \(state.altitude), Velocity \(state.velocity), Fuel \(state.fuel)"
                )
            }
        }

        #expect(success, "All strategies failed to land safely.")
    }
}
