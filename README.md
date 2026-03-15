# Frontend for cthree

## Basic Conventions

The code follows a model-repo-provider architecture where models define the data, repositories intercat with the API to get data and return the suitable models, and providers provide data needed throughout the app such as current user etc.


A signle instance of Dio is used for all API call with custom interceptors to deal with authentication headers and refreshing of tokens.