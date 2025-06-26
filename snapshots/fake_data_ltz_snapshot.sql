{% snapshot fake_data_ltz_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='timestamp',
        updated_at='loaded_at',
    )
}}

select * from {{ ref('fake_data_ltz') }}

{% endsnapshot %} 