<?php

namespace App\Filament\Clusters\Bid;

use BackedEnum;
use Filament\Clusters\Cluster;
use Filament\Pages\Enums\SubNavigationPosition;
use Filament\Support\Icons\Heroicon;

class BidCluster extends Cluster
{
    protected static ?string $navigationLabel = 'Заявки';
    protected static ?string $title = 'Заявки';
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedQueueList;
    protected static ?SubNavigationPosition $subNavigationPosition = SubNavigationPosition::Top;
}
