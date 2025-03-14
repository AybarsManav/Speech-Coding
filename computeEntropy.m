function entropy = computeEntropy(probabilities)
    entropy = -sum(probabilities .* log2(probabilities + 1e-12));
end

