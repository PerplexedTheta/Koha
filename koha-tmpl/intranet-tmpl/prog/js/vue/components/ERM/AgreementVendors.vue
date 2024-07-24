<template>
    <fieldset class="rows" id="agreement_vendors">
        <legend>{{ $__("Vendors") }}</legend>
        <fieldset
            :id="`agreement_vendor_${counter}`"
            class="rows"
            v-for="(agreement_vendor, counter) in agreement_vendors"
            v-bind:key="counter"
        >
            <legend>
                {{ $__("Agreement vendor %s").format(counter + 1) }}
                <a href="#" @click.prevent="deleteVendor(counter)"
                    ><i class="fa fa-trash"></i>
                    {{ $__("Remove this vendor") }}</a
                >
            </legend>
            <ol>
                <li>
                    <label :for="`agreement_vendor_id_${counter}`" class="required"
                        >{{ $__("Vendor") }}:</label
                    >
                    <v-select
                        :id="`agreement_vendor_id_${counter}`"
                        label="name"
                        :reduce="vendor => vendor.id"
                        :options="vendorOptions"
                        :filter-by="filterVendors"
                    >
                        <template v-slot:option="v">
                            {{ v.name }}
                            <br />
                            <cite>{{ v.aliases.map(a => a.alias).join(", ") }}</cite>
                        </template>
                    </v-select>
                    <span class="required">{{ $__("Required") }}</span>
                </li>
            </ol>
        </fieldset>
        <a
            v-if="vendors.length"
            class="btn btn-default"
            @click="addVendor"
            ><font-awesome-icon icon="plus" />
            {{ $__("Add new vendor") }}</a
        >
        <span v-else>{{
            $__("There are no vendors created yet")
        }}</span>
    </fieldset>
</template>

<script>
import { inject } from "vue"
import { storeToRefs } from "pinia"

export default {
    name: "AgreementVendors",
    setup() {
        const vendorStore = inject("vendorStore")
        const { vendors } = storeToRefs(vendorStore)
        return { vendors }
    },
    computed: {
        vendorOptions() {
            return this.vendors.map(v => ({
                ...v,
                full_search:
                    v.name +
                    (v.aliases.length > 0
                        ? " (" + v.aliases.map(a => a.alias).join(", ") + ")"
                        : ""),
            }))
        },
    },
    methods: {
        filterVendors(vendor, label, search) {
            return (
                (vendor.full_search || "")
                    .toLocaleLowerCase()
                    .indexOf(search.toLocaleLowerCase()) > -1
            )
        },
        addVendor() {
            this.agreement_vendors.push({
                vendor_id: null,
                vendor: { name: "" },
            })
        },
        deleteVendor(counter) {
            this.agreement_vendors.splice(counter, 1)
        },
    },
    props: {
        agreement_vendors: Array,
    },
}
</script>
