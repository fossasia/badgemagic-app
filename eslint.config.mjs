import {FlatCompat} from '@eslint/eslintrc';
import pluginJs from '@eslint/js';
import eslintPrettierConfig from 'eslint-config-prettier';
import eslintPluginPrettier from 'eslint-plugin-prettier';
import pluginReactConfig from 'eslint-plugin-react/configs/recommended.js';
import globals from 'globals';
import path from 'path';
import {fileURLToPath} from 'url';

// mimic CommonJS variables -- not needed if using CommonJS
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: pluginJs.configs.recommended,
});

export default [
  {languageOptions: {globals: globals.node}},
  ...compat.extends('standard-with-typescript'),
  pluginReactConfig,
  eslintPrettierConfig,
  {ignores: ['*.config.*', '.yarn', '.prettierrc.js', '.expo']},
  {
    files: ['**/*.ts', '**/*.tsx', '**/*.js', '**/*.jsx'],
    plugins: {
      prettier: eslintPluginPrettier,
    },
    rules: {
      semi: 'off',
      '@typescript-eslint/semi': 'off',
      'react/react-in-jsx-scope': 'off',
      '@typescript-eslint/strict-boolean-expressions': 'off',
      '@typescript-eslint/no-misused-promises': [
        'error',
        {
          checksVoidReturn: false,
        },
      ],
    },
  },
];
