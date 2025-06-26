{% snapshot fake_data_ntz_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='timestamp',
        updated_at='loaded_at',
    )
}}

select * from {{ ref('fake_data_ntz') }}

{% endsnapshot %} 