public virtual class TriggerHandler {
    // Called by the factory to set context
    public virtual void setContext(List<SObject> newList, List<SObject> oldList) {}

    // Trigger lifecycle methods
    public virtual void beforeInsert() {}
    public virtual void beforeUpdate() {}
    public virtual void beforeDelete() {}
    public virtual void afterInsert() {}
    public virtual void afterUpdate() {}
    public virtual void afterDelete() {}
    public virtual void afterUndelete() {}
}