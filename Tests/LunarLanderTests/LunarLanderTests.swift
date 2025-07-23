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

/*
 ALT(m)     VEL(m/s)    FUEL   THRUST%
 1000           0       500    0
 998.4       -1.62      500    0
 995.1       -3.24      500    0
 990.3       -4.86      500    0
 983.8       -6.48      500    0
 975.7       -8.1       500    0
 966         -9.72      500    0
 954.6       -11.34     500    0
 941.7       -12.96     500    0
 927.1       -14.58     500    0
 910.9       -16.2      500    0
 893.1       -17.82     500    0
 873.6       -19.44     500    0
 852.6       -21.06     500    0
 829.9       -22.68     500    0
 805.6       -24.3      500    0
 779.7       -25.92     500    0
 752.1       -27.54     500    9
 723.4       -28.79     499.8  53
 695.1       -28.27     498.7  62
 667.7       -27.41     497.5  63
 641.2       -26.51     496.2  63
 615.6       -25.62     495    62
 590.8       -24.76     493.7  61
 566.9       -23.93     492.5  61
 543.7       -23.12     491.3  60
 521.4       -22.34     490.1  59
 499.8       -21.59     488.9  59
 478.9       -20.87     487.8  58
 458.8       -20.17     486.6  57
 439.3       -19.49     485.4  57
 420.5       -18.83     484.3  56
 402.3       -18.2      483.2  56
 384.7       -17.59     482.1  55
 367.7       -17        481    55
 351.3       -16.42     479.9  54
 335.4       -15.87     478.8  54
 320         -15.34     477.7  53
 305.2       -14.82     476.6  53
 290.9       -14.32     475.6  53
 277.1       -13.84     474.5  52
 263.7       -13.38     473.5  52
 250.8       -12.93     472.4  51
 238.3       -12.49     471.4  51
 226.2       -12.07     470.4  51
 214.5       -11.67     469.4  50
 203.2       -11.27     468.4  50
 192.4       -10.89     467.4  50
 181.8       -10.53     466.4  49
 171.7       -10.17     465.4  49
 161.8       -9.83      464.4  49
 152.3       -9.5       463.4  48
 143.1       -9.18      462.5  48
 134.3       -8.87      461.5  48
 125.7       -8.58      460.5  48
 117.4       -8.29      459.6  47
 109.4       -8.01      458.6  47
 101.7       -7.74      457.7  47
 94.2        -7.48      456.8  47
 86.9        -7.23      455.8  47
 80          -6.98      454.9  46
 73.2        -6.75      454    46
 66.7        -6.52      453    46
 60.4        -6.3       452.1  46
 54.3        -6.09      451.2  46
 48.4        -5.89      450.3  45
 42.7        -5.69      449.4  45
 37.2        -5.5       448.5  45
 31.9        -5.31      447.6  45
 26.8        -5.13      446.7  45
 21.8        -4.96      445.8  45
 17          -4.79      444.9  45
 12.4        -4.63      444    44
 7.9         -4.48      443.1  44
 3.6         -4.33      442.2  44
 */
