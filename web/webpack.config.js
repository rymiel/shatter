/* eslint-disable */
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const webpack = require('webpack');

const config = {
  entry: path.join(__dirname, 'src', 'index.tsx'),
  target: 'web',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      }
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
  },
  output: {
    filename: '[name].bundle.js',
    path: path.resolve(__dirname, '..', 'public', 'dist'),
    publicPath: '/dist/'
  },
  plugins: [
      new HtmlWebpackPlugin({
          template: path.join(__dirname, 'src', 'index.html'),
          filename: path.join(__dirname, '..', 'public', 'index.html')
      }),
      new webpack.EnvironmentPlugin({'HOT_REDIRECT': null})
  ]
};

module.exports = (env, argv) => {
  if (argv.mode === "development") {
    config.devtool = 'inline-source-map';
    config.devServer = {
      static: '../public',
      hot: true,
    }
  } else if (argv.mode === "production") {
    config.optimization = {
      splitChunks: {
        chunks: 'all',
      }
    }
  }
  return config;
}