import * as ts from "typescript";
import { cwd } from "process";
import { declarationTransformer, transformer } from "@deepkit/type-compiler";
import { readFile } from "fs/promises";

export default function deepkitType(options = {}){
  return {
    name: "Deepkit",
    setup(build) {
      const transformers = options.transformers || {
        before: [transformer],
        after: [declarationTransformer],
      };

      build.onLoad({ filter: /\.tsx?$/ }, async (args) => {
        const configFilePath = options.tsConfig || cwd() + "/tsconfig.json";

        const code = await readFile(args.path, { encoding: 'utf8' });
        const transformed = ts.transpileModule(code, {
          compilerOptions: Object.assign(
            {
              target: ts.ScriptTarget.ESNext,
              module: ts.ModuleKind.ESNext,
              sourceMap: false,
              skipDefaultLibCheck: true,
              skipLibCheck: true,
              configFilePath,
            },
            options || {},
          ),
          fileName: args.path,
          moduleName: args.namespace,
          transformers,
        });

        return {
          contents: transformed.outputText,
          loader: args.path.endsWith('.tsx') ? 'tsx' : 'ts'
        };
      });
    },
  };
}
