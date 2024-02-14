qsortable_components() = ["q-draggable-tree-node" => js"""{
template: `
  <div>
    <div style="border-radius: 3px;"
         :class="hasChildren?'q-tree__node--link':'q-tree__node--link q-treeview-node--leaf'"
    >
      <div style="padding-top: 6px;" class="row q-treeview-node__root" @click="open = !open">
        <q-icon size="sm" v-if="hasChildren" name="arrow_right"
                :class="open?'text-grey-8 q-tree__arrow--rotate':'text-grey-8'"/>
        <slot name="left" v-bind=" { item: value, open } "/>
        <slot v-if="hasDefaultSlot" name="body" v-bind=" { item: value, open } "/>
        <div v-if="!hasDefaultSlot" class="q-tree__node-header-content q-pa-xs">
          {{ value.label }}
        </div>
      </div>
      <div
          v-if="open && value.children.length > 0"
          class="q-tree__children"
          style="padding-top: 6px"
      >
        <draggable
            :list="value.children"
            item-key="name" :group="group"
            @input="updateValue"
            ghost-class="ghost"
            @start="drag = true"
            @end="drag = false"
        >
          <q-draggable-tree-node v-for="(item,index) in value.children"
                                 :key="index"
                                 :value="item"
                                 @input="updateChildValue"
                                 :group="group"
                                 :rowKey="rowKey"
          >
            <template #left=" { item:element, open } ">
              <slot name="left" v-bind=" { item:element, open } "></slot>
            </template>
            <template v-if="hasDefaultSlot" #body=" { item:element, open } ">
              <slot name="body" v-bind=" { item:element, open } "></slot>
            </template>
            <span v-if="!hasDefaultSlot">{{ item.label }}</span>
          </q-draggable-tree-node>
        </draggable>
      </div>
      <div v-else class="q-tree__children">
        <draggable
            item-key="name"
            :list="value.children"
            ghost-class="ghost"
            @input="updateValue"
            :group="group"
            class="dragArea"
            @start="drag = true"
            @end="drag = false"
        >
        </draggable>
      </div>
    </div>
  </div>`,
    props: {
        value: {
        type: Object,
        default: () => ({
            id: 0,
            name: "",
            children: []
        })
        },
        root: {
        type: Boolean,
        default: () => false
        },
        group: {
        type: String,
        default: null
        },
        rowKey: {
        type: String,
        default: 'label'
        },
    },
    data() {
        return {
        open: Vue.ref(true),
        drag: Vue.ref(false),
        localValue: Vue.ref(this.value),
        enabled: true,
        list: [
            {name: "John", id: 0},
            {name: "Joao", id: 1},
            {name: "Jean", id: 2}
        ],
        dragging: false
        };
    },
    computed: {
        hasChildren() {
        return this.value.children != null && this.value.children.length > 0;
        },
        isDark() {
        return "";
        },
        hasDefaultSlot() {
        return this.$slots.hasOwnProperty("body");
        },
        dragOptions() {
        return {
            animation: 200,
            group: "description",
            emptyInsertThreshold: 10,
            disabled: false,
            ghostClass: "ghost"
        };
        }
    },
    watch: {
        value(value) {
        this.localValue = Object.assign({}, value);
        }
    },
    methods: {
        updateValue(value) {
        if (value.constructor === Array) {
            this.localValue.children = [...value];
            this.$emit("input", this.localValue);
            this.open = true;
        }
        },
        updateChildValue(value) {
        const index = this.localValue.children.findIndex(c => c[this.rowKey] === value[this.rowKey]);
        this.localValue.children[index] = value
        this.$emit("input", this.localValue);
        }
    },
    emits: ['input']
}
""",

"q-draggable-tree" => js"""{
    template: `
  <div class="q-pa-md q-gutter-sm">
    <q-draggable-tree-node
        v-for="(item, index) in treeData" v-bind:value="item" v-bind:group="group" v-on:input="updateItem" v-bind:rowKey="rowKey"
    >
      <template v-slot:left=" { item: item, open: open } ">
        <slot name="left" v-bind:item="item" v-bind:open="open"></slot>
      </template>
      <template v-if="hasDefaultSlot" v-slot:body=" { item, open } ">
        <slot name="body" v-bind=" { item, open } "></slot>
      </template>
      <span v-if="!hasDefaultSlot">{{ item }}</span>
    </q-draggable-tree-node>
  </div>
`,
    props: {
        data: {
        type: Array,
        default: () => {
            return [];
        }
        },
        group: {
        type: String,
        default: null
        },
        rowKey: {
        type: String,
        default: 'label'
        },
    },
    data() {
        return {
        drag: Vue.ref(false),
        localValue: Vue.ref([...this.data])
        };
    },
    computed: {
        treeData: {
        get() {
            return this.data
        },
        set(val) {
            // We should not update original data
        }
        },
        themeClassName() {
        return 'theme--dark';
        },
        hasDefaultSlot() {
        return this.$slots.hasOwnProperty("body");
        },
        dragOptions() {
        return {
            animation: 200,
            group: "description",
            emptyInsertThreshold: 10,
            disabled: false,
            ghostClass: "ghost"
        };
        }
    },
    watch: {
        value(value) {
        this.localValue = [...value];
        }
    },
    methods: {
        updateValue(value) {
        this.localValue = value;
        this.$emit("input", this.localValue);
        },
        updateItem(itemValue) {
        const index = this.localValue.findIndex(v => v[this.rowKey] === itemValue[this.rowKey]);
        this.localValue[index] = itemValue
        this.$emit("input", this.localValue);
        }
    }
}
"""]
