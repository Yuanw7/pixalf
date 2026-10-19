#include "simulation.h"
#include <iostream>
int main(){Simulation simulation;std::string line;while(std::getline(std::cin,line))std::cout<<simulation.command(line)<<std::endl;}
