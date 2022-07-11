Vue.component('QSortableTreeNode', {
    template: `
<draggable :style="{'min-height': dragAreaHeight + 'px'}"
    tag="div"
    :list="nodes"
    :group="{ name: 'QSortableTree' }"
    :animation="200">
<div v-for="node in nodes"
  :key="node[nodeKey]"
  class="q-tree__node relative-position"
  :class="{'q-tree__node--parent': !isLeaf(node), 'q-tree__node--child': isLeaf(node)}"
  @dblclick.stop="$emit('dblclick', node)"
  @click.right.stop.prevent="$emit('rightclick', node)"
  @click.left.stop="$emit('select', node)">

 <div :tabindex="node.disabled ? -1 : 0"
      :class="{'q-tree__node--disabled': node.disabled, 'q-hoverable q-focusable': !node.disabled, 'q-tree__node--selected': selected === node[nodeKey]}"
      class="q-tree__node-header relative-position row no-wrap items-center q-tree__node--link"
      @mouseenter.stop="$emit('mouseenter', node)"
      @mouseover.stop="$emit('mouseover', node)"
      @mouseleave.stop="$emit('mouseleave', node)">
     <div tabindex="-1" class="q-focus-helper"></div>
     <svg aria-hidden="true" role="presentation" focusable="false" viewBox="0 0 24 24" class="q-tree__arrow q-mr-xs q-icon notranslate"
          v-if="node[childrenKey].length > 0"
          :class="{'q-tree__arrow--rotate': !node.collapsed}"
          @click.stop="toggleCollapse(node)">
         <path d="M8,5.14V19.14L19,12.14L8,5.14Z"></path>
     </svg>
     <div class="q-tree__node-header-content col row no-wrap items-center">
         <slot name="default-header" :node="node" :label-key="labelKey">
             <q-avatar v-if="node.avatar" class="q-mr-sm">
                 <img :src="node.avatar">
             </q-avatar>
             <q-icon v-if="node.icon" :name="node.icon" class="q-mr-sm"/>
             <div>
                 {{ node[labelKey] }}
             </div>
         </slot>
     </div>
 </div>

 <div class="q-tree__node-collapsible" v-if="nodeCanHaveChildren(node)">
     <div class="q-tree__node-body relative-position" v-if="hasDefaultBodySlot">
         <slot name="default-body"></slot>
     </div>
     <div class="q-tree__children" v-show="!node.collapsed">
         <q-sortable-tree-node :nodes="node[childrenKey]"
                               :node-key="nodeKey"
                               :label-key="labelKey"
                               :children-key="childrenKey"
                               :leaf-key="leafKey"
                               :parent-node="node"
                               :default-expand-all="!node.collapsed"
                               :selected="selected"
                               :drag-area-height="dragAreaHeight"
                               @dblclick="$emit('dblclick', $event)"
                               @rightclick="$emit('rightclick', $event)"
                               @select="$emit('select', $event)"
                               @mouseenter="$emit('mouseenter', $event)"
                               @mouseover="$emit('mouseover', $event)"
                               @mouseleave="$emit('mouseleave', $event)">
             <template v-slot:default-header="props">
                 <slot name="default-header" v-bind="props"></slot>
             </template>
             <template v-slot:default-body="props">
                 <slot name="default-body" v-bind="props"></slot>
             </template>
         </q-sortable-tree-node>
     </div>
 </div>

</div>
</draggable>
</template>`,
    props: {
        nodes: {
            required: true,
            type: Array
        },
        nodeKey: {
            required: true,
            type: String
        },
        labelKey: {
            required: false,
            type: String,
            default: 'label'
        },
        childrenKey: {
            required: false,
            type: String,
            default: 'children'
        },
        leafKey: {
            required: false,
            type: String,
            default: 'leaf',
        },
        parentNode: {
            required: false,
            type: Object,
            default: null
        },
        defaultExpandAll: {
            required: false,
            type: Boolean,
            default: false
        },
        selected: {
            required: false,
            type: String,
            default: null,
        },
        dragAreaHeight: {
            required: false,
            type: Number,
            default: 1,
        },
    },
    methods: {
        toggleCollapse(node) {
            if (!this.isLeaf(node) && !node.disabled) {
                node.collapsed = !node.collapsed;
            }
        },
        isLeaf(node) {
            return !(node.hasOwnProperty(this.childrenKey) && node[this.childrenKey].length > 0);
        },
        nodeCanHaveChildren(node) {
            return !node.hasOwnProperty(this.leafKey) || (node.hasOwnProperty(this.leafKey) && node[this.leafKey] === false);
        },
    },
    computed: {
        hasDefaultBodySlot() {
            return !!this.$slots.defaultBody;
        },
    },
    components: {
        // draggable
    },
    name: 'QSortableTreeNode',
});

Vue.component('QSortableTree', {
    template: `
    <q-sortable-tree-node :nodes="nodes"
    :node-key="nodeKey"
    :label-key="labelKey"
    :children-key="childrenKey"
    :leaf-key="leafKey"
    :default-expand-all="defaultExpandAll"
    class="q-tree"
    :class="{'q-tree--no-connectors': noConnectors}"
    :selected="selected"
    :drag-area-height="dragAreaHeight"
    @select="$emit('select', $event)"
    @dblclick="$emit('dblclick', $event)"
    @rightclick="$emit('rightclick', $event)"
    @mouseenter="$emit('mouseenter', $event)"
    @mouseover="$emit('mouseover', $event)"
    @mouseleave="$emit('mouseleave', $event)">
<template v-slot:default-header="props">
<slot name="default-header" v-bind="props"></slot>
</template>
<template v-slot:default-body="props">
<slot name="default-body" v-bind="props"></slot>
</template>
</q-sortable-tree-node>
  `,
  components: {
    //   QSortableTreeNode
    },
  props: {
      nodes: {
          required: true,
          type: Array,
      },
      nodeKey: {
          required: true,
          type: String,
      },
      labelKey: {
          required: false,
          type: String,
          default: 'label',
      },
      childrenKey: {
          required: false,
          type: String,
          default: 'children',
      },
      leafKey: {
          required: false,
          type: String,
          default: 'leaf',
      },
      defaultExpandAll: {
          required: false,
          type: Boolean,
          default: false,
      },
      noConnectors: {
          required: false,
          type: Boolean,
          default: false,
      },
      selected: {
          required: false,
          type: String,
          default: null,
      },
      dragAreaHeight: {
          required: false,
          type: Number,
          default: 1,
      },
  },
  created() {
      this.repairNodes(this.nodes);
  },
  watch: {
      nodes: {
          deep: true,
          handler() {
              this.repairNodes(this.nodes);
              this.$emit('change', this.nodes);
          },
      },
  },
  methods: {
      repairNodes(nodes) {
          nodes.forEach((node) => {
              if (!node.hasOwnProperty(this.childrenKey) || !Array.isArray(node[this.childrenKey])) {
                  this.$set(node, this.childrenKey, []);
              } else {
                  this.repairNodes(node[this.childrenKey]);
              }

              if (!node.hasOwnProperty('collapsed')) {
                  if (node.disabled) {
                      this.$set(node, 'collapsed', true);
                  } else {
                      this.$set(node, 'collapsed', this.isLeaf(node) ? false : !this.defaultExpandAll);
                  }
              }
          });
      },
      isLeaf(node) {
          return !(node.hasOwnProperty(this.childrenKey) && node[this.childrenKey].length > 0);
      },
  }

});

