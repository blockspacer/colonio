/*
 * Copyright 2017-2020 Yuji Ito <llamerada.jp@gmail.com>
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

#include <colonio/constant.hpp>
#include <exception>
#include <string>

namespace colonio {

/**
 * @brief Error information. This is used when the asynchronous method calls a failed callback.
 *
 * The code and message are set to the same content as the Exception.
 *
 * @sa ErrorCode,
 *     Exception
 */
class Error {
 public:
  /// Code to indicate the cause of the error.
  const ErrorCode code;
  /// A detailed message string for display or bug report.
  const std::string message;

  /**
   * @brief Construct a new Error object.
   *
   * @param code_ Code to indicate the cause of the error.
   * @param message_ A detailed message string for display or bug report.
   */
  explicit Error(ErrorCode code_, const std::string& message_);
};
}  // namespace colonio
