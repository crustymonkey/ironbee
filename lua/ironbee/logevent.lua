-- =========================================================================
-- Licensed to Qualys, Inc. (QUALYS) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- QUALYS licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- =========================================================================

-------------------------------------------------------------------
-- IronBee - LogEvent
--
-- A security event generated by IronBee rules.
--
-- @module ironbee.logevent
--
-- @copyright Qualys, Inc., 2010-2014
-- @license Apache License, Version 2.0
--
-- @author Sam Baskinger <sbaskinger@qualys.com>
-------------------------------------------------------------------

local ibutil = require('ironbee/util')
local ffi = require('ffi')
require('ironbee-ffi-h')

local M = {}
M.__index = M

-------------------------------------------------------------------
-------------------------------------------------------------------
M.new = function(self, event)
    local o = { raw = event }
    return setmetatable(o, self)
end

-------------------------------------------------------------------
-- Map of string logevent suppression to numeric.
-------------------------------------------------------------------
M.suppressMap = {
    none           = tonumber(ffi.C.IB_LEVENT_SUPPRESS_NONE),
    false_positive = tonumber(ffi.C.IB_LEVENT_SUPPRESS_FPOS),
    replaced       = tonumber(ffi.C.IB_LEVENT_SUPPRESS_REPLACED),
    incomplete     = tonumber(ffi.C.IB_LEVENT_SUPPRESS_INC),
    partial        = tonumber(ffi.C.IB_LEVENT_SUPPRESS_INC),
    other          = tonumber(ffi.C.IB_LEVENT_SUPPRESS_OTHER)
}

-------------------------------------------------------------------
-- Reverse Map of numeric logevent suppression to string.
-------------------------------------------------------------------
M.suppressRmap = {}
for k,v in pairs(M.suppressMap) do
    M.suppressRmap[v] = k
end

-------------------------------------------------------------------
-- Map of string logevent type to numeric.
-------------------------------------------------------------------
M.typeMap = {
    unknown        = tonumber(ffi.C.IB_LEVENT_TYPE_UNKNOWN),
    observation    = tonumber(ffi.C.IB_LEVENT_TYPE_OBSERVATION),
    alert          = tonumber(ffi.C.IB_LEVENT_TYPE_ALERT),
}

-------------------------------------------------------------------
-- Reverse Map of numeric logevent type to string.
-------------------------------------------------------------------
M.typeRmap = {}
for k,v in pairs(M.typeMap) do
    M.typeRmap[v] = k
end

-------------------------------------------------------------------
-- Get the logevent severity.
--
-- @tparam logevent self Logevent object.
--
-- @treturn number Logevent severity.
-------------------------------------------------------------------
M.getSeverity = function(self)
    return self.raw.severity
end

-------------------------------------------------------------------
-- Get the logevent confidence.
--
-- @tparam logevent self Logevent object.
--
-- @treturn number Logevent confidence.
-------------------------------------------------------------------
M.getConfidence = function(self)
    return self.raw.confidence
end

-------------------------------------------------------------------
-- Get the logevent action.
--
-- @tparam logevent self Logevent object.
--
-- @treturn number Logevent action.
-------------------------------------------------------------------
M.getAction = function(self)
    return self.raw.action
end

-------------------------------------------------------------------
-- Get the logevent rule ID.
--
-- @tparam logevent self Logevent object.
--
-- @treturn string Logevent rule ID.
-------------------------------------------------------------------
M.getRuleId = function(self)
    return ffi.string(self.raw.rule_id)
end

-------------------------------------------------------------------
-- Get the logevent message.
--
-- @tparam logevent self Logevent object.
--
-- @treturn string Logevent message.
-------------------------------------------------------------------
M.getMsg = function(self)
    return ffi.string(self.raw.msg)
end

-------------------------------------------------------------------
-- Get the logevent suppression.
--
-- @tparam logevent self Logevent object.
--
-- @treturn number Logevent suppression.
-------------------------------------------------------------------
M.getSuppress = function(self)
    return M.suppressRmap[tonumber(self.raw.suppress)]
end

-------------------------------------------------------------------
-- Set logevent suppression.
--
-- On an event object set the suppression value using a number or name.
--
-- value - may be none, false_positive, replaced, incomplete, partial or other.
--         The value of none indicates that there is no suppression of the event.
--
-- @tparam logevent self Logevent object.
-- @tparam string|number value Value to set.
-------------------------------------------------------------------
M.setSuppress = function(self, value)
    if type(value) == "number" then
        self.raw.suppress = value
    else
        self.raw.suppress = M.suppressMap[string.lower(value)] or 0
    end
end

-------------------------------------------------------------------
-- Get the logevent type.
--
-- @tparam logevent self Logevent object.
--
-- @treturn number Logevent type.
-------------------------------------------------------------------
M.getType = function(self)
    return M.typeRmap[tonumber(self.raw.type)]
end

-------------------------------------------------------------------
-- Set logevent type.
--
-- @tparam logevent self Logevent object.
-- @tparam string|number value Value to set.
-------------------------------------------------------------------
M.setType = function(self, value)
    if type(value) == "number" then
        self.raw.type = value
    else
        self.raw.type = M.typeMap[string.lower(value)] or 0
    end
end

-------------------------------------------------------------------
-- Execute a function for each field name in the logevent.
--
-- @tparam logevent self Logevent object.
-- @tparam function func Function to execute with name as argument.
-------------------------------------------------------------------
M.forEachField = function(self, func)
    if self.raw.fields ~= nil then
        ibutil.each_list_node(
            self.raw.fields,
            function(charstar)
                func(ffi.string(charstar))
            end,
            "char*")
    end
end

-------------------------------------------------------------------
-- Execute a function for each tag name in the logevent.
--
-- @tparam logevent self Logevent object.
-- @tparam function func Function to execute with name as argument.
-------------------------------------------------------------------
M.forEachTag = function(self, func)
    if self.raw.tags ~= nil then
        ibutil.each_list_node(
            self.raw.tags,
            function(charstar)
                func(ffi.string(charstar))
            end,
            "char*")
    end
end

-- Iteration function used by e:tags.
-- Given a table with an element "node" of type ib_list_node_t*
-- this will iterate across the nodes extracting the
-- ib_list_node_data as a string.
--
-- This is used by e:tags() and e:fields().
local next_string_fn = function(t, idx)
    local data

    if t.node == nil then
        return nil, nil
    else
        data = ffi.C.ib_list_node_data(t.node)
        data = ffi.string(data)
    end

    t.node = ffi.cast("ib_list_node_t*", ffi.C.ib_list_node_next(t.node))

    return idx + 1, data
end

-------------------------------------------------------------------
-- Get a logevent fields iterator.
--
-- @usage for i,v in levent:tags() do ... end
--
-- @tparam logevent self Logevent object.
--
-- @treturn iterator Logevent tags.
-------------------------------------------------------------------
M.fields = function()
    local t = {
        node = ffi.cast("ib_list_node_t*", ffi.C.ib_list_first(self.raw.fields))
    }

    -- return function, table, and index before first.
    return next_string_fn, t, 0
end

-------------------------------------------------------------------
-- Get a logevent tags iterator.
--
-- @usage for i,v in levent:tags() do ... end
--
-- @tparam logevent self Logevent object.
--
-- @treturn iterator Logevent tags.
-------------------------------------------------------------------
M.tags = function(self)
    local t = {
        node = ffi.cast("ib_list_node_t*", ffi.C.ib_list_first(self.raw.tags))
    }

    -- return function, table, and index before first.
    return next_string_fn, t, 0
end

-------------------------------------------------------------------
-- Add a tag to the logevent.
--
-- @tparam logevent self Logevent object.
-- @tparam string value Value to add.
-------------------------------------------------------------------
M.addTag = function(self, value)
    if self.raw.tags ~= nil then
        ffi.C.ib_list_push(self.raw.tags, ffi.cast("void*", tostring(value)))
    end
end

return M
