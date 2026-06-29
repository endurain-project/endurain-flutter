/// Shared sentinel for `copyWith` methods that need to distinguish "argument
/// omitted" from "explicitly set to null". Compare with [identical] against
/// [kUnset]: a parameter still equal to [kUnset] was not supplied, so the
/// existing value is kept; any other value (including `null`) replaces it.
const Object kUnset = Object();
