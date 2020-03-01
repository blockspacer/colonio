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

#include "system_1d.hpp"

namespace colonio {
System1DDelegate::~System1DDelegate() {
}

System1D::System1D(
    Context& context, APIModuleDelegate& module_delegate, System1DDelegate& system_delegate, APIChannel::Type channel,
    APIModuleChannel::Type module_channel) :
    APIModule(context, module_delegate, channel, module_channel),
    delegate(system_delegate) {
}

bool System1D::system_1d_check_covered_range(const NodeID& nid) {
  return delegate.system_1d_do_check_covered_range(*this, nid);
}
}  // namespace colonio
