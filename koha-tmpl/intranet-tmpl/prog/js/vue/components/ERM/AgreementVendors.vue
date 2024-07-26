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
                        v-model="agreement_vendor.id"
                        label="name"
                        :reduce="a => a.id"
                        :options="vendors"
                        :filter-by="filterVendors"
                    >
                        <template #search="{ attributes, events }">
                            <input
                                :required="!agreement_vendor.id"
                                class="vs__search"
                                v-bind="attributes"
                                v-on="events"
                            />
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
import { APIClient } from "../../fetch/api-client.js"

export default {
    data() {
        return {
            vendors: [],
        }
    },
    beforeCreate() {
        const acq_client = APIClient.acquisition
        acq_client.vendors.getAll().then(
            vendors => {
                this.vendors = vendors
            },
            error => {}
        )
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
                id: null,
            })
        },
        deleteVendor(counter) {
            this.agreement_vendors.splice(counter, 1)
        },
    },
    props: {
        agreement_vendors: Array,
    },
    name: "AgreementVendors",
}
</script>
