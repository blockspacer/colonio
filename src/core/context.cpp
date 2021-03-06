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
#include "context.hpp"

#include <cassert>

#include "coord_system.hpp"
#include "logger.hpp"

namespace colonio {

Context::Context(Logger& logger_, Scheduler& scheduler_) :
    link_status(LinkStatus::OFFLINE), logger(logger_), scheduler(scheduler_), local_nid(NodeID::make_random()) {
}

Coordinate Context::get_local_position() {
  assert(coord_system);

  return coord_system->get_local_position();
}

bool Context::has_local_position() {
  assert(coord_system);

  return coord_system->get_local_position().is_enable();
}

void Context::hook_on_change_local_position(std::function<void(const Coordinate&)> func) {
  funcs_on_change_local_position.push_back(func);
}

void Context::set_local_position(const Coordinate& pos) {
  assert(coord_system);

  Coordinate prev_local_position = coord_system->get_local_position();
  coord_system->set_local_position(pos);
  Coordinate new_local_position = coord_system->get_local_position();

  if (prev_local_position.x != new_local_position.x || prev_local_position.y != new_local_position.y) {
    logI((*this), "change local position").map_float("x", new_local_position.x).map_float("y", new_local_position.y);

    for (auto& it : funcs_on_change_local_position) {
      it(new_local_position);
    }
  }
}
}  // namespace colonio
