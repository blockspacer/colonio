/*
 * Copyright 2019 Yuji Ito <llamerada.jp@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#pragma once

#include <exception>
#include <string>

#include "utils.hpp"

namespace colonio {
/**
 * THROW_EX macro is helper function to throw exception with line number and file name.
 * @param FORMAT Format string of an exception message that similar to printf.
 */
#define THROW_EX(FORMAT, ...) throw Exception(__LINE__, __FILE__, Utils::format_string(FORMAT, 0, ##__VA_ARGS__))

/**
 * Exception class is for throwing when error and exception on processing in any module.
 * It containing line no, file name and a message string for display or bug report.
 */
class Exception : public std::exception {
 public:
  /// The line number where the exception was thrown.
  const unsigned long line;
  /// The file name where the exception was thrown.
  const std::string file;
  /// A message string for display or bug report.
  const std::string message;

  Exception(int l, const std::string& f, const std::string& m);

  /**
   * Pass message without line-no and file name.
   */
  const char* what() const noexcept override;
};
}  // namespace colonio
