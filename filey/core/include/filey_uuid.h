#pragma once
#include <string>
#include <random>
#include <sstream>
#include <iomanip>

namespace filey {

// Generates a version-4 UUID string: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
inline std::string generateUUID() {
    std::random_device rd;
    std::mt19937_64 gen(rd());
    std::uniform_int_distribution<uint32_t> dist(0, 0xFFFFFFFF);

    uint32_t a  = dist(gen);
    uint16_t b  = dist(gen) & 0xFFFF;
    uint16_t c  = (dist(gen) & 0x0FFF) | 0x4000;   // version 4
    uint16_t d  = (dist(gen) & 0x3FFF) | 0x8000;   // variant bits
    uint32_t e1 = dist(gen);
    uint16_t e2 = dist(gen) & 0xFFFF;

    std::ostringstream ss;
    ss << std::hex << std::setfill('0')
       << std::setw(8) << a    << '-'
       << std::setw(4) << b    << '-'
       << std::setw(4) << c    << '-'
       << std::setw(4) << d    << '-'
       << std::setw(8) << e1
       << std::setw(4) << e2;
    return ss.str();
}

} // namespace filey
