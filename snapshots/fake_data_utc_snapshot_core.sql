{% snapshot fake_data_utc_snapshot_core %}

{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='timestamp',
        updated_at='loaded_at',
    )
}}

select * from {{ ref('fake_data_utc') }}

{% endsnapshot %} 