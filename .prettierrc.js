module.exports = {
  bracketSpacing: false,
  bracketSameLine: true,
  singleQuote: true,
  printWidth: 100,
  trailingComma: 'all',
  importOrder: ['^(react|react-native)$', '<THIRD_PARTY_MODULES>', '^@/(.*)$', '^[./]'],
  importOrderSeparation: true,
  plugins: ['@trivago/prettier-plugin-sort-imports'],
};
