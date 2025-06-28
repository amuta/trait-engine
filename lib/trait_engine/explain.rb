TraitEngine::DSL.build { … } # (temporary Ruby DSL in test)
processor.resolve_attribute(:promo_code, ctx)  # returns value
processor.explain(:promo_code, ctx)            # JSON trace
