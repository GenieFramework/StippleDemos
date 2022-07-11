Vue.component('QDraggableTree', {
    template: `<div class="q-pa-md q-gutter-sm">
  
      <draggable
              :value="localValue"
              :group="group"
              v-model="treeData"
              class="q-tree q-tree-draggable"
              ghost-class="ghost"
              @input="updateValue"
              v-bind="dragOptions"
              @start="drag = true"
              @end="drag = false"
      >
          <transition-group type="transition" :name="!drag ? 'flip-list' : null">
              <q-draggable-tree-node
                      v-for="item, index in treeData"
                      :key="index"
                      :value="item"
                      :group="group"
                      @input="updateItem"
                      :rowKey="rowKey"
              >
                  <template v-slot:left="{ item, open }">
                      <slot name="left" v-bind="{ item, open }"></slot>
                  </template>
                  <template v-if="hasDefaultSlot" v-slot:body="{ item, open }">
                      <slot name="body" v-bind="{ item, open }"></slot>
                  </template>
                  <span v-if="!hasDefaultSlot">{{item}}</span>
              </q-draggable-tree-node>
          </transition-group>
      </draggable>
  </div>`,
    props: {
      data: {
        type: Array,
        default: () => {
          return [];
        } },
  
      group: {
        type: String,
        default: null },
  
      rowKey: {
        type: String,
        default: 'label' } },
  
  
    data() {
      return {
        drag: false,
        localValue: [...this.data] };
  
    },
    computed: {
      treeData: {
        get() {
          return this.data;
        },
        set(val) {
          // We should not update original data
        } },
  
      themeClassName() {
        return 'theme--dark';
      },
      hasDefaultSlot() {
        return this.$scopedSlots.hasOwnProperty("body");
      },
      dragOptions() {
        return {
          animation: 200,
          group: "description",
          disabled: false,
          ghostClass: "ghost" };
  
      } },
  
    watch: {
      value(value) {
        this.localValue = [...value];
      } },
  
    methods: {
      updateValue(value) {
        this.localValue = value;
        this.$emit("input", this.localValue);
      },
      updateItem(itemValue) {
        const index = this.localValue.findIndex(v => v[this.rowKey] === itemValue[this.rowKey]);
        this.$set(this.localValue, index, itemValue);
        this.$emit("input", this.localValue);
      } } 
});
  

Vue.component('QDraggableTreeNode', {
    template: `
  <div
          :class="hasChildren?'q-tree__node--link':'q-tree__node--link q-treeview-node--leaf'"
  >
      <div class="row q-treeview-node__root" @click="open = !open">
          <q-icon size="sm" v-if="hasChildren" name="arrow_right"
                  :class="open?'text-grey-8 q-tree__arrow--rotate':'text-grey-8'"/>
          <slot name="left" v-bind="{ item: value, open }"/>
          <slot v-if="hasDefaultSlot" name="body" v-bind="{ item: value, open }"/>
          <div v-if="!hasDefaultSlot" class="q-tree__node-header-content q-pa-xs">
              {{value.label}}
          </div>
      </div>
      <div
              v-if="open"
              class="q-tree__children"
      >
          <draggable
                  :value="value.children"
                  ghost-class="ghost"
                  @input="updateValue"
                  :group="group"
                  v-bind="dragOptions"
                  @start="drag = true"
                  @end="drag = false"
          >
              <transition-group type="transition" :name="!drag ? 'flip-list' : null">
                  <q-draggable-tree-node
                          v-for="item,index in value.children"
                          :key="index"
                          :value="item"
                          @input="updateChildValue"
                          :group="group"
                          :rowKey="rowKey"
                  >
                      <template v-slot:left="{ item, open }">
                          <slot name="left" v-bind="{ item, open }"></slot>
                      </template>
                      <template v-if="hasDefaultSlot" v-slot:body="{ item, open }">
                          <slot name="body" v-bind="{ item, open }"></slot>
                      </template>
                      <span v-if="!hasDefaultSlot">{{item.label}}</span>
                  </q-draggable-tree-node>
              </transition-group>
          </draggable>
      </div>
  </div>`,
    name: "QDraggableTreeNode",
    props: {
      value: {
        type: Object,
        default: () => ({
          id: 0,
          name: "",
          children: [] }) },
  
  
      root: {
        type: Boolean,
        default: () => false },
  
      group: {
        type: String,
        default: null },
  
      rowKey: {
        type: String,
        default: 'label' } },
  
  
    data() {
      return {
        open: false,
        drag: false,
        localValue: Object.assign({}, this.value) };
  
    },
    computed: {
      hasChildren() {
        return this.value.children != null && this.value.children.length > 0;
      },
      isDark() {
        return "";
      },
      hasDefaultSlot() {
        return this.$scopedSlots.hasOwnProperty("body");
      },
      dragOptions() {
        return {
          animation: 200,
          group: "description",
          disabled: false,
          ghostClass: "ghost" };
  
      } },
  
    watch: {
      value(value) {
        this.localValue = Object.assign({}, value);
      } },
  
    methods: {
      updateValue(value) {
        if (value.constructor == Array) {
          this.localValue.children = [...value];
          this.$emit("input", this.localValue);
        }
      },
      updateChildValue(value) {
        const index = this.localValue.children.findIndex(c => c[this.rowKey] === value[this.rowKey]);
        this.$set(this.localValue.children, index, value);
        this.$emit("input", this.localValue);
      } } 
});