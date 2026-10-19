#pragma once
#include <string>
#include <chrono>
extern "C" {
#include "quickjs.h"
}
class Simulation {
 JSRuntime *runtime=nullptr;
 JSContext *context=nullptr;
 bool booted=false;
 std::chrono::steady_clock::time_point deadline;
 static int interrupted(JSRuntime *, void *opaque);
 void reset();
 std::string failure();
 std::string string(JSValueConst value);
 std::string error(const std::string &message);
 public:
 Simulation();
 ~Simulation();
 Simulation(const Simulation&)=delete;
 Simulation& operator=(const Simulation&)=delete;
 std::string command(const std::string &input);
};
