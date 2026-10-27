// Org ESLint base: vanilla JS + JSDoc house style, ESLint 9 flat config. Spread it, then add globals/files blocks.
import js from '@eslint/js'
import jsdoc from 'eslint-plugin-jsdoc'

export default [
  js.configs.recommended,
  jsdoc.configs['flat/recommended'],
  {
    rules: {
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-case-declarations': 'warn',
      'no-empty': ['error', { allowEmptyCatch: true }],
      'jsdoc/require-jsdoc': [
        'warn',
        {
          require: {
            FunctionDeclaration: true,
            MethodDefinition: false,
            ClassDeclaration: false,
            ArrowFunctionExpression: false,
            FunctionExpression: false,
          },
        },
      ],
      'jsdoc/check-param-names': 'error',
      'jsdoc/check-tag-names': 'off',
      'jsdoc/no-undefined-types': 'off',
    },
  },
  { ignores: ['**/node_modules/**', '**/.wrangler/**', '**/dist/**', '**/types/**'] },
]
