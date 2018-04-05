//
// HTMLHelpers.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

func h3(_ string: String, bottomMargin: Bool = true) -> String {
    return "<div style='font-weight:bold; font-size: 125%; margin-bottom:\(bottomMargin ? "8" : "0")px'>\(string)</div>"
}

func h4(_ string: String, bottomMargin: Bool = true) -> String {
    return "<div style='font-weight:bold; font-size: 100%; margin-bottom:\(bottomMargin ? "8" : "0")px'>\(string)</div>"
}
