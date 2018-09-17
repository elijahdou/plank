//
//  ObjectiveCBuilderExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/14/17.
//
//

import Foundation

extension ObjCModelRenderer {

    // MARK: Builder methods

    func renderBuilderInitWithModel() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithModel:(\(self.className) *)model") {
            [
                "NSParameterAssert(model);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                "if (!(self = [super initWithModel:model])) { return self; }",
                "struct \(self.dirtyPropertyOptionName) \(self.dirtyPropertiesIVarName) = model.\(self.dirtyPropertiesIVarName);",

                self.properties.map ({ (param, _) -> String in
                    ObjCIR.ifStmt("\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                        ["_\(param.snakeCaseToPropertyName()) = model.\(param.snakeCaseToPropertyName());"]
                    }
                }).joined(separator: "\n"),
                "_\(self.dirtyPropertiesIVarName) = \(self.dirtyPropertiesIVarName);",
                "return self;"
            ]
        }
    }

    func renderBuilderPropertySetters() -> [ObjCIR.Method] {

        func renderBuilderPropertySetter(_ param: Parameter, _ schema: Schema) -> String {
            switch schema.memoryAssignmentType() {
            case .copy:
                return "[\(param.snakeCaseToPropertyName()) copy];"
            default:
                return "\(param.snakeCaseToPropertyName());"
            }
        }

        return self.properties.map({ (param, prop) -> ObjCIR.Method in
            ObjCIR.method("- (void)set\(param.snakeCaseToCapitalizedPropertyName()):(\(typeFromSchema(param, prop)))\(param.snakeCaseToPropertyName())") {
                [
                    "_\(param.snakeCaseToPropertyName()) = \(renderBuilderPropertySetter(param, prop.schema))",
                    "_\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) = 1;"
                ]
            }
        })
    }

    func renderBuilderMergeWithModel() -> ObjCIR.Method {
        func formatParam(_ param: String, _ schema: Schema, _ nullability: Nullability?) -> String {
            return ObjCIR.ifStmt("model.\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                func loop(_ schema: Schema, _ nullability: Nullability?) -> [String] {
                    switch schema {
                    case .object:
                        var stmt = ObjCIR.ifElseStmt("builder.\(param.snakeCaseToPropertyName())") {[
                                "builder.\(param.snakeCaseToPropertyName()) = [builder.\(param.snakeCaseToPropertyName()) mergeWithModel:value];"
                            ]} {[
                                "builder.\(param.snakeCaseToPropertyName()) = value;"
                            ]}
                        switch nullability {
                        case .some(.nullable): stmt = ObjCIR.ifElseStmt("value != nil") {[ stmt ]} {[ "builder.\(param.snakeCaseToPropertyName()) = nil;" ]}
                        case .some(.nonnull), .none: break
                        }
                        return [
                            "id value = model.\(param.snakeCaseToPropertyName());",
                            stmt
                        ]
                    case .reference(with: let ref):
                        switch ref.force() {
                        case .some(.object(let objSchema)):
                            return loop(.object(objSchema), nullability)
                        default:
                            fatalError("Error identifying reference for \(param) in \(schema)")
                        }
                    default:
                        return ["builder.\(param.snakeCaseToPropertyName()) = model.\(param.snakeCaseToPropertyName());"]
                    }
                }
                return loop(schema, nullability)
            }
        }

        return ObjCIR.method("- (void)mergeWithModel:(\(self.className) *)model") {
            [
                "NSParameterAssert(model);",
                self.isBaseClass ? "" : "[super mergeWithModel:model];",
                self.properties.count > 0 ? "\(self.builderClassName) *builder = self;" : "",
                self.properties.map { ($0.0, $0.1.schema, $0.1.nullability) }.map(formatParam).joined(separator: "\n")
                ].filter { $0 != "" }
        }
    }
}
