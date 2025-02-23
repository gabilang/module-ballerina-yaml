// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import yaml.emitter;
import yaml.serializer;
import yaml.composer;

# Parses a Ballerina string of YAML content into a Ballerina map object.
#
# + yamlString - YAML content
# + config - Configuration for reading a YAML file
# + return - YAML map object on success. Else, returns an error
public isolated function readString(string yamlString, *ReadConfig config) returns json|Error {
    composer:ComposerState composerState = check new ([yamlString],
        generateTagHandlesMap(config.yamlTypes, config.schema), config.allowAnchorRedefinition,
        config.allowMapEntryRedefinition);
    return composer:composeDocument(composerState);
}

# Parses a YAML file into a Ballerina json object.
#
# + filePath - Path to the YAML file
# + config - Configuration for reading a YAML file
# + return - YAML map object on success. Else, returns an error
public isolated function readFile(string filePath, *ReadConfig config) returns json|Error {
    string[] lines = check io:fileReadLines(filePath);
    composer:ComposerState composerState = check new (lines, generateTagHandlesMap(config.yamlTypes, config.schema),
        config.allowAnchorRedefinition, config.allowMapEntryRedefinition);
    return config.isStream ? composer:composeStream(composerState) : composer:composeDocument(composerState);
}

# Converts the YAML structure to an array of strings.
#
# + yamlStructure - Structure to be written to the file
# + config - Configurations for writing a YAML file
# + return - YAML content on success. Else, an error on failure
public isolated function writeString(json yamlStructure, *WriteConfig config) returns string[]|Error {
    serializer:SerializerState serializerState = {
        events: [],
        tagSchema: generateTagHandlesMap(config.yamlTypes, config.schema),
        blockLevel: config.blockLevel,
        delimiter: config.useSingleQuotes ? "'" : "\"",
        forceQuotes: config.forceQuotes
    };
    check serializer:serialize(serializerState, yamlStructure);

    emitter:EmitterState emitterState = new (
        events = serializerState.events,
        customTagHandles = config.customTagHandles,
        indentationPolicy = config.indentationPolicy,
        canonical = config.canonical
    );
    return emitter:emit(emitterState, isStream = config.isStream);
}

# Writes the YAML structure to a file.
#
# + filePath - Path to the file  
# + yamlStructure - Structure to be written to the file
# + config - Configurations for writing a YAML file
# + return - An error on failure
public isolated function writeFile(string filePath, json yamlStructure, *WriteConfig config) returns Error? {
    check openFile(filePath);
    string[] output = check writeString(yamlStructure, config);
    check io:fileWriteLines(filePath, output);
}
