import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import globals from 'globals'

export default [
  { ignores: ['dist/**', 'node_modules/**', '.local-safety/**', '.npm-cache/**'] },
  { files: ['src/**/*.{js,jsx,ts,tsx}', 'tests/**/*.mjs', 'vite.config.js'], languageOptions: { parser: tseslint.parser, ecmaVersion: 'latest', sourceType: 'module', parserOptions: { ecmaFeatures: { jsx: true } }, globals: { ...globals.browser, ...globals.node } }, rules: { ...js.configs.recommended.rules, 'no-unused-vars': 'off', 'no-undef': 'off' } },
  { files: ['src/**/*.{js,jsx}', 'tests/**/*.mjs', 'vite.config.js'], rules: { 'no-undef': 'error' } },
]
